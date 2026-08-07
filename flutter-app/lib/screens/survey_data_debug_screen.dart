import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/station.dart';
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
      body: Consumer<StorageService>(
        builder: (context, storageService, _) {
          final stations = storageService.stations;
          final legs = storageService.legs;

          if (stations.isEmpty) {
            return Center(
              child: Text(
                'No survey data collected yet',
                style: AppTextStyles.body.copyWith(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.backgroundSecondary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stations: ${stations.length}',
                      style: AppTextStyles.headline.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Legs: ${legs.length}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stations table
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('Stations',
                            style: AppTextStyles.headline
                                .copyWith(fontSize: 14, color: Colors.cyan)),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.backgroundSecondary,
                          ),
                          dataRowMinHeight: 32,
                          dataRowMaxHeight: 40,
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: _ColHeader('#')),
                            DataColumn(label: _ColHeader('Depth (m)')),
                          ],
                          rows: stations
                              .map((s) => DataRow(
                                    color: WidgetStateProperty.all(
                                      AppColors.actionExportCSV
                                          .withOpacity(0.1),
                                    ),
                                    cells: [
                                      DataCell(
                                          _buildMonospaceText('${s.number}')),
                                      DataCell(_buildMonospaceText(
                                          s.depth.toStringAsFixed(2))),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Legs table
                      if (legs.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('Survey Legs',
                              style: AppTextStyles.headline
                                  .copyWith(fontSize: 14, color: Colors.cyan)),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.backgroundSecondary,
                            ),
                            dataRowMinHeight: 32,
                            dataRowMaxHeight: 40,
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(label: _ColHeader('From')),
                              DataColumn(label: _ColHeader('To')),
                              DataColumn(label: _ColHeader('Dist (m)')),
                              DataColumn(label: _ColHeader('Azim (°)')),
                              DataColumn(label: _ColHeader('L')),
                              DataColumn(label: _ColHeader('R')),
                              DataColumn(label: _ColHeader('U')),
                              DataColumn(label: _ColHeader('D')),
                            ],
                            rows: legs.map((leg) {
                              final fromStation = stations
                                  .where((s) => s.id == leg.fromStationId)
                                  .firstOrNull;
                              final toStation = stations
                                  .where((s) => s.id == leg.toStationId)
                                  .firstOrNull;
                              return DataRow(cells: [
                                DataCell(_buildMonospaceText(
                                    '${fromStation?.number ?? '?'}')),
                                DataCell(_buildMonospaceText(
                                    '${toStation?.number ?? '?'}')),
                                DataCell(_buildMonospaceText(
                                    leg.distance.toStringAsFixed(2))),
                                DataCell(_buildMonospaceText(
                                    leg.heading.toStringAsFixed(1))),
                                DataCell(_buildMonospaceText(
                                    leg.left.toStringAsFixed(1))),
                                DataCell(_buildMonospaceText(
                                    leg.right.toStringAsFixed(1))),
                                DataCell(_buildMonospaceText(
                                    leg.up.toStringAsFixed(1))),
                                DataCell(_buildMonospaceText(
                                    leg.down.toStringAsFixed(1))),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
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

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    );
  }
}
