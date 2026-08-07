import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/station.dart';

/// Service for exporting and importing survey data
class ExportService {
  /// Export survey data to CSV format
  Future<File> exportToCSV(
    List<Station> stations,
    List<SurveyLeg> legs,
    String fileName,
  ) async {
    final buffer = StringBuffer();

    // Stations section
    buffer.writeln('[Stations]');
    buffer.writeln('number,depth,timestamp');
    for (final s in stations) {
      buffer.writeln(
        '${s.number},'
        '${s.depth},'
        '${s.timestamp.toIso8601String()}',
      );
    }

    buffer.writeln();

    // Legs section
    buffer.writeln('[Legs]');
    buffer.writeln('fromStation,toStation,distance,heading,left,right,up,down,timestamp');
    final stationMap = {for (final s in stations) s.id: s};
    for (final leg in legs) {
      final fromNum = stationMap[leg.fromStationId]?.number ?? 0;
      final toNum = stationMap[leg.toStationId]?.number ?? 0;
      buffer.writeln(
        '$fromNum,'
        '$toNum,'
        '${leg.distance},'
        '${leg.heading},'
        '${leg.left},'
        '${leg.right},'
        '${leg.up},'
        '${leg.down},'
        '${leg.timestamp.toIso8601String()}',
      );
    }

    return _writeFile(fileName, buffer.toString());
  }

  /// Export survey data to Therion diving format
  Future<File> exportToTherion(
    List<Station> stations,
    List<SurveyLeg> legs,
    String surveyName,
  ) async {
    return _writeFile(
        '$surveyName.th', buildTherionContent(stations, legs, surveyName));
  }

  /// Build the Therion .th file content as a string.
  String buildTherionContent(
      List<Station> stations, List<SurveyLeg> legs, String surveyName) {
    final buffer = StringBuffer();
    final stationMap = {for (final s in stations) s.id: s};

    // Derive survey date from the first station's timestamp.
    String surveyDate = '';
    if (stations.isNotEmpty) {
      final ts = stations.first.timestamp;
      surveyDate =
          '${ts.year}.${ts.month.toString().padLeft(2, '0')}.${ts.day.toString().padLeft(2, '0')}';
    }

    buffer.writeln('encoding  utf-8');
    buffer.writeln('');
    buffer.writeln('survey $surveyName');
    buffer.writeln('');
    buffer.writeln('  centerline');
    buffer.writeln('    date $surveyDate');
    buffer.writeln('');
    buffer.writeln('    walls on');
    buffer.writeln('    units length depth meters');
    buffer.writeln('    units compass degrees');
    buffer.writeln('');
    buffer.writeln('    data diving from to length compass fromdepth todepth');

    for (final leg in legs) {
      final from = stationMap[leg.fromStationId];
      final to = stationMap[leg.toStationId];
      if (from == null || to == null) continue;

      buffer.writeln(
        '    ${from.number.toString().padLeft(3)}  ${to.number.toString().padLeft(2)}'
        '  ${leg.distance.toStringAsFixed(2).padLeft(7)}'
        '  ${leg.heading.toStringAsFixed(2).padLeft(7)}'
        '  ${from.depth.toStringAsFixed(1).padLeft(5)}'
        '  ${to.depth.toStringAsFixed(1)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('    data dimensions station left right up down');
    // Use first connected leg's LRUD for each station (Therion expects one set per station)
    final stationLrud = <int, SurveyLeg>{};
    for (final leg in legs) {
      stationLrud.putIfAbsent(leg.toStationId, () => leg);
    }
    for (final station in stations) {
      final leg = stationLrud[station.id];
      if (leg != null) {
        buffer.writeln(
          '    ${station.number} '
          '${leg.left.toStringAsFixed(2)} '
          '${leg.right.toStringAsFixed(2)} '
          '${leg.up.toStringAsFixed(2)} '
          '${leg.down.toStringAsFixed(2)}',
        );
      }
    }
    buffer.writeln('  endcenterline');
    buffer.writeln('');
    buffer.writeln('endsurvey');

    return buffer.toString();
  }

  /// Writes content to a file in a platform-specific accessible location.
  ///
  /// On Android: Saves to /storage/emulated/0/Documents/CaveDiveMap
  /// - Accessible via Files app and file managers
  /// - Requires WRITE_EXTERNAL_STORAGE permission (Android 12 and below)
  ///
  /// On iOS: Saves to Documents/CaveDiveMap
  /// - Accessible via Files app
  ///
  /// Both platforms create a "CaveDiveMap" subfolder to organize exports.
  Future<File> _writeFile(String fileName, String content) async {
    Directory exportDir;

    if (Platform.isAndroid) {
      // On Android API 29+, use scoped storage with MediaStore approach
      // For now, use the external storage root + Documents folder
      final externalDir = await getExternalStorageDirectory();

      if (externalDir != null) {
        // Navigate to the public Documents folder: /storage/emulated/0/Documents/CaveDiveMap
        // Strip the app-specific path and go to root
        final storagePath = externalDir.path.split('/Android')[0];
        exportDir = Directory('$storagePath/Documents/CaveDiveMap');
      } else {
        throw Exception('External storage not available');
      }
    } else {
      // On iOS, use Documents directory - accessible via Files app
      final baseDirectory = await getApplicationDocumentsDirectory();
      exportDir = Directory('${baseDirectory.path}/CaveDiveMap');
    }

    // Create directory if it doesn't exist
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final file = File('${exportDir.path}/$fileName');
    return file.writeAsString(content);
  }

  /// Share file using the platform's native share dialog.
  ///
  /// Opens the system share sheet allowing the user to share the file
  /// via messaging apps, email, cloud storage, etc.
  Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }

  /// Export survey data to CSV and immediately share via system dialog.
  Future<File> exportAndShareCSV(
    List<Station> stations,
    List<SurveyLeg> legs,
    String fileName,
  ) async {
    final file = await exportToCSV(stations, legs, fileName);
    await shareFile(file, 'Survey Data: $fileName');
    return file;
  }

  /// Export survey data to Therion format and immediately share via system dialog.
  Future<File> exportAndShareTherion(
    List<Station> stations,
    List<SurveyLeg> legs,
    String surveyName,
  ) async {
    final file = await exportToTherion(stations, legs, surveyName);
    await shareFile(file, 'Therion Survey: $surveyName');
    return file;
  }

  /// Import survey data from a CSV file selected by the user.
  /// Returns parsed stations and legs as a record.
  Future<({List<Station> stations, List<SurveyLeg> legs})> importFromCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      throw Exception('Invalid file path');
    }

    final file = File(filePath);
    final content = await file.readAsString();

    return parseCSV(content);
  }

  /// Parse CSV content with [Stations] and [Legs] sections.
  ({List<Station> stations, List<SurveyLeg> legs}) parseCSV(String content) {
    final lines = content.split('\n').map((l) => l.trim()).toList();

    final stations = <Station>[];
    final legs = <SurveyLeg>[];

    String? currentSection;
    bool headerSkipped = false;

    for (final line in lines) {
      if (line.isEmpty) {
        currentSection = null;
        headerSkipped = false;
        continue;
      }

      if (line == '[Stations]') {
        currentSection = 'stations';
        headerSkipped = false;
        continue;
      } else if (line == '[Legs]') {
        currentSection = 'legs';
        headerSkipped = false;
        continue;
      }

      if (currentSection == null) continue;

      // Skip header row
      if (!headerSkipped) {
        headerSkipped = true;
        continue;
      }

      final parts = line.split(',');

      if (currentSection == 'stations') {
        if (parts.length < 3) {
          throw FormatException('Invalid station row: $line');
        }
        stations.add(Station(
          number: int.parse(parts[0]),
          depth: double.parse(parts[1]),
          timestamp: DateTime.parse(parts[2]),
        ));
      } else if (currentSection == 'legs') {
        if (parts.length < 9) {
          throw FormatException('Invalid leg row: $line');
        }
        legs.add(SurveyLeg(
          fromStationId: int.parse(parts[0]),
          toStationId: int.parse(parts[1]),
          distance: double.parse(parts[2]),
          heading: double.parse(parts[3]),
          left: double.parse(parts[4]),
          right: double.parse(parts[5]),
          up: double.parse(parts[6]),
          down: double.parse(parts[7]),
          timestamp: DateTime.parse(parts[8]),
        ));
      }
    }

    if (stations.isEmpty) {
      throw FormatException('No stations found in CSV file');
    }

    return (stations: stations, legs: legs);
  }
}
