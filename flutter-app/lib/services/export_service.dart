import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/survey_data.dart';

/// Service for exporting survey data to CSV and Therion formats
class ExportService {
  /// Export survey data to CSV format
  Future<File> exportToCSV(List<SurveyData> surveyPoints, String fileName) async {
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln('recordNumber,distance,heading,depth,left,right,up,down,rtype,timestamp');

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
        '${point.timestamp.toIso8601String()}'
      );
    }

    return _writeFile(fileName, buffer.toString());
  }

  /// Export survey data to Therion format
  Future<File> exportToTherion(List<SurveyData> surveyPoints, String surveyName) async {
    final buffer = StringBuffer();

    // Therion header
    buffer.writeln('survey $surveyName -title "$surveyName"');
    buffer.writeln('');
    buffer.writeln('  centerline');
    buffer.writeln('    units length meters');
    buffer.writeln('    units compass degrees');
    buffer.writeln('    data normal from to length compass clino');
    buffer.writeln('');

    // Generate Therion survey data
    for (int i = 0; i < surveyPoints.length - 1; i++) {
      final from = surveyPoints[i];
      final to = surveyPoints[i + 1];

      final legLength = to.distance - from.distance;
      final compass = to.heading;

      final depthChange = to.depth - from.depth;
      double clino = 0.0;
      if (legLength > 0.001) {
        clino = _radiansToDegrees(_calculateClino(depthChange, legLength));
      }

      buffer.writeln('    ${from.recordNumber} ${to.recordNumber} '
          '${legLength.toStringAsFixed(2)} '
          '${compass.toStringAsFixed(1)} '
          '${clino.toStringAsFixed(1)}');
    }

    buffer.writeln('  endcenterline');
    buffer.writeln('');

    buffer.writeln('  centerline');
    buffer.writeln('    data dimensions station left right up down');
    for (final point in surveyPoints) {
      if (point.rtype == 'manual') {
        buffer.writeln('    ${point.recordNumber} '
            '${point.left.toStringAsFixed(2)} '
            '${point.right.toStringAsFixed(2)} '
            '${point.up.toStringAsFixed(2)} '
            '${point.down.toStringAsFixed(2)}');
      }
    }
    buffer.writeln('  endcenterline');
    buffer.writeln('');
    buffer.writeln('endsurvey');

    return _writeFile('$surveyName.th', buffer.toString());
  }

  static double _calculateClino(double depthChange, double horizontalDistance) {
    return -1 * atan(depthChange / horizontalDistance);
  }

  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / pi;
  }

  Future<File> _writeFile(String fileName, String content) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    return file.writeAsString(content);
  }

  /// Share file using platform share dialog
  Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
    );
  }

  Future<void> exportAndShareCSV(
    List<SurveyData> surveyPoints,
    String fileName,
  ) async {
    final file = await exportToCSV(surveyPoints, fileName);
    await shareFile(file, 'Survey Data: $fileName');
  }

  Future<void> exportAndShareTherion(
    List<SurveyData> surveyPoints,
    String surveyName,
  ) async {
    final file = await exportToTherion(surveyPoints, surveyName);
    await shareFile(file, 'Therion Survey: $surveyName');
  }
}
