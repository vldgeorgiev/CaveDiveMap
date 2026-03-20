import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/survey_data.dart';

/// Service for exporting and importing survey data
class ExportService {
  /// Export survey data to CSV format
  Future<File> exportToCSV(
    List<SurveyData> surveyPoints,
    String fileName,
  ) async {
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln(
      'recordNumber,distance,heading,depth,left,right,up,down,rtype,timestamp',
    );

    // CSV rows
    for (final point in surveyPoints) {
      buffer.writeln(
        '${point.recordNumber},'
        '${point.distance},'
        '${point.heading},'
        '${point.depth},'
        '${point.left},'
        '${point.right},'
        '${point.up},'
        '${point.down},'
        '${point.rtype},'
        '${point.timestamp.toIso8601String()}',
      );
    }

    return _writeFile(fileName, buffer.toString());
  }

  /// Export survey data to Therion diving format
  Future<File> exportToTherion(
    List<SurveyData> surveyPoints,
    String surveyName,
  ) async {
    return _writeFile('$surveyName.th', buildTherionContent(surveyPoints, surveyName));
  }

  /// Build the Therion .th file content as a string.
  ///
  /// Exposed for testing; use [exportToTherion] for normal export.
  String buildTherionContent(List<SurveyData> surveyPoints, String surveyName) {
    final buffer = StringBuffer();

    // Skip auto-collected intermediate points; only survey stations are exported.
    final stations = surveyPoints.where((p) => p.rtype != 'auto').toList();

    // Derive survey date from the first station's timestamp.
    String surveyDate = '';
    if (stations.isNotEmpty) {
      final ts = stations.first.timestamp;
      surveyDate =
          '${ts.year}.${ts.month.toString().padLeft(2, '0')}.${ts.day.toString().padLeft(2, '0')}';
    }

    // File header
    buffer.writeln('encoding  utf-8');
    buffer.writeln('');
    buffer.writeln('survey $surveyName -title "$surveyName"');
    buffer.writeln('');
    buffer.writeln('  centerline');
    buffer.writeln('    date $surveyDate');
    buffer.writeln('');
    buffer.writeln('    walls on');
    buffer.writeln('    units length depth meters');
    buffer.writeln('    units compass degrees');
    buffer.writeln('');
    buffer.writeln('    # Converted from $surveyName.csv');
    buffer.writeln(
      '    # CSV columns: cumulative distance, heading (forward compass), absolute depth',
    );
    buffer.writeln(
      '    # Leg lengths = difference of consecutive cumulative distances',
    );
    buffer.writeln('    data diving from to length compass fromdepth todepth');

    for (int i = 0; i < stations.length - 1; i++) {
      final from = stations[i];
      final to = stations[i + 1];

      final legLength = to.distance - from.distance;
      // Compass is the forward bearing recorded AT the from-station (looking
      // toward the to-station). This matches the map-screen convention which
      // uses manualPoints[i-1].heading (the from-point heading) to plot legs.
      final compass = from.heading;
      final fromDepth = from.depth;
      final toDepth = to.depth;

      buffer.writeln(
        '    ${i.toString().padLeft(3)}  ${(i + 1).toString().padLeft(2)}'
        '  ${legLength.toStringAsFixed(2).padLeft(7)}'
        '  ${compass.toStringAsFixed(2).padLeft(7)}'
        '  ${fromDepth.toStringAsFixed(1).padLeft(5)}'
        '  ${toDepth.toStringAsFixed(1)}',
      );
    }
    buffer.writeln('  endcenterline');
    buffer.writeln('');

    buffer.writeln('  centerline');
    buffer.writeln('    data dimensions station left right up down');
    for (int i = 0; i < stations.length; i++) {
      final point = stations[i];
      if (point.rtype == 'manual') {
        buffer.writeln(
          '    $i '
          '${point.left.toStringAsFixed(2)} '
          '${point.right.toStringAsFixed(2)} '
          '${point.up.toStringAsFixed(2)} '
          '${point.down.toStringAsFixed(2)}',
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
  ///
  /// Convenience method combining exportToCSV() and shareFile().
  Future<File> exportAndShareCSV(
    List<SurveyData> surveyPoints,
    String fileName,
  ) async {
    final file = await exportToCSV(surveyPoints, fileName);
    await shareFile(file, 'Survey Data: $fileName');
    return file;
  }

  /// Export survey data to Therion format and immediately share via system dialog.
  ///
  /// Convenience method combining exportToTherion() and shareFile().
  Future<File> exportAndShareTherion(
    List<SurveyData> surveyPoints,
    String surveyName,
  ) async {
    final file = await exportToTherion(surveyPoints, surveyName);
    await shareFile(file, 'Therion Survey: $surveyName');
    return file;
  }

  /// Import survey data from a CSV file selected by the user.
  ///
  /// Opens a file picker dialog allowing the user to select a CSV file.
  /// Parses the CSV and returns a list of SurveyData objects.
  ///
  /// Throws:
  /// - [Exception] if no file is selected
  /// - [FormatException] if CSV format is invalid
  Future<List<SurveyData>> importFromCSV() async {
    // Open file picker
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

    return _parseCSV(content);
  }

  /// Parse CSV content into list of SurveyData objects
  List<SurveyData> _parseCSV(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      throw FormatException('CSV file is empty');
    }

    // Verify header
    final header = lines[0].trim();
    if (header != 'recordNumber,distance,heading,depth,left,right,up,down,rtype,timestamp') {
      throw FormatException(
        'Invalid CSV header. Expected: recordNumber,distance,heading,depth,left,right,up,down,rtype,timestamp',
      );
    }

    final surveyData = <SurveyData>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length != 10) {
        throw FormatException('Invalid CSV row at line ${i + 1}: expected 10 columns, got ${parts.length}');
      }

      try {
        surveyData.add(SurveyData(
          recordNumber: int.parse(parts[0]),
          distance: double.parse(parts[1]),
          heading: double.parse(parts[2]),
          depth: double.parse(parts[3]),
          left: double.parse(parts[4]),
          right: double.parse(parts[5]),
          up: double.parse(parts[6]),
          down: double.parse(parts[7]),
          rtype: parts[8],
          timestamp: DateTime.parse(parts[9]),
        ));
      } catch (e) {
        throw FormatException('Error parsing CSV row at line ${i + 1}: $e');
      }
    }

    if (surveyData.isEmpty) {
      throw FormatException('No valid data found in CSV file');
    }

    return surveyData;
  }
}
