import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/survey_data.dart';
import '../utils/theme_extensions.dart';

/// Debug screen for viewing survey data in table format
class SurveyDataDebugScreen extends StatelessWidget {
  const SurveyDataDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Survey Data Debug'),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: FutureBuilder<List<SurveyData>>(
        future: context.read<StorageService>().getAllSurveyData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading survey data: ${snapshot.error}',
                style: AppTextStyles.body.copyWith(color: Colors.red),
              ),
            );
          }

          final surveyData = snapshot.data ?? [];

          if (surveyData.isEmpty) {
            return Center(
              child: Text(
                'No survey data collected yet',
                style: AppTextStyles.body.copyWith(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // Header with point count
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.backgroundSecondary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Points: ${surveyData.length}',
                      style: AppTextStyles.headline.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Manual: ${surveyData.where((d) => d.rtype == 'manual').length}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              // Data table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.backgroundSecondary,
                      ),
                      dataRowMinHeight: 32,
                      dataRowMaxHeight: 40,
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(
                          label: Text(
                            '#',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Dist (m)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Azim (°)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Depth (m)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Left (m)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Right (m)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Up (m)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Down (m)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Type',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      rows: surveyData.map((point) {
                        final isManual = point.rtype == 'manual';
                        return DataRow(
                          color: WidgetStateProperty.all(
                            isManual
                                ? AppColors.actionExportCSV.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          cells: [
                            DataCell(
                              _buildMonospaceText('${point.recordNumber}'),
                            ),
                            DataCell(
                              _buildMonospaceText(
                                point.distance.toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              _buildMonospaceText(
                                point.heading.toStringAsFixed(1),
                              ),
                            ),
                            DataCell(
                              _buildMonospaceText(
                                point.depth.toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              _buildMonospaceText(
                                point.left.toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              _buildMonospaceText(
                                point.right.toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              _buildMonospaceText(point.up.toStringAsFixed(2)),
                            ),
                            DataCell(
                              _buildMonospaceText(
                                point.down.toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              Text(
                                point.rtype,
                                style: TextStyle(
                                  color: isManual
                                      ? AppColors.actionExportCSV
                                      : Colors.grey,
                                  fontWeight: isManual
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonospaceText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: Colors.white,
      ),
    );
  }
}
