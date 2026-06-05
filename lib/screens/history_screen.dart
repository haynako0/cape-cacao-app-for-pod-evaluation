import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../models/history_entry.dart';
import '../onnx_service.dart';
import '../providers/navigation_provider.dart';
import 'analytics_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _showAnalytics = false;

  bool _sortAscending = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedFilterClasses = [];

  final List<String> _filterOptions = ['Healthy', 'Blackpod', 'Mirid', 'PodBorer', 'No Detections'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateFull(BuildContext context, DateTime date) {
    final String timeString = TimeOfDay.fromDateTime(date).format(context);
    const List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final String month = months[date.month - 1];
    return "$month ${date.day}, ${date.year} $timeString";
  }

  String _formatDateShort(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  List<HistoryEntry> _getFilteredEntries(List<HistoryEntry> allEntries) {
    List<HistoryEntry> filtered = List.from(allEntries);

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((entry) {
        return entry.originalFileName.toLowerCase().contains(query);
      }).toList();
    }

    if (_startDate != null) {
      filtered = filtered.where((entry) {
        return entry.date.isAfter(_startDate!.subtract(const Duration(seconds: 1)));
      }).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((entry) {
        return entry.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    if (_selectedFilterClasses.isNotEmpty) {
      filtered = filtered.where((entry) {
        if (_selectedFilterClasses.contains('No Detections') && entry.detections.isEmpty) {
          return true;
        }
        final Set<String> entryLabels = entry.detections
            .map((d) => d.label.toUpperCase().trim())
            .toSet();

        return _selectedFilterClasses.any((filterClass) {
          if (filterClass == 'No Detections') return false;
          return entryLabels.contains(filterClass.toUpperCase().trim());
        });
      }).toList();
    }

    filtered.sort((a, b) {
      return _sortAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredEntries = _getFilteredEntries(historyProvider.historyEntries);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: _showAnalytics ? null : 80,
        titleSpacing: 16,

        leading: _showAnalytics
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
              tooltip: settings.translate('back'),
              onPressed: () {
                settings.playTapSound();
                setState(() {
                  _showAnalytics = false;
                });
              },
            )
          : null,

        title: _showAnalytics
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "History Analytics",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            )
          : Container(
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                textAlignVertical: TextAlignVertical.center,
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: "${settings.translate('search')}...",
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: colorScheme.onSurface),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                ),
              ),
            ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showAnalytics ? colorScheme.secondary : colorScheme.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _showAnalytics ? Icons.list_rounded : Icons.bar_chart_rounded,
                  size: 22,
                  color: _showAnalytics ? colorScheme.onSecondary : colorScheme.onTertiaryContainer,
                ),
                padding: EdgeInsets.zero,
                tooltip: _showAnalytics ? "List View" : "Analytics",
                onPressed: () {
                  settings.playTapSound();
                  setState(() {
                    _showAnalytics = !_showAnalytics;
                  });
                },
              ),
            ),
          ),

          if (!_showAnalytics) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (_startDate != null || _endDate != null || _selectedFilterClasses.isNotEmpty)
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: (_startDate != null || _endDate != null || _selectedFilterClasses.isNotEmpty)
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSecondaryContainer,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: settings.translate('filter_sort'),
                  onPressed: () => _showFilterDialog(context, settings),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(150),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_sweep_rounded,
                    size: 20,
                    color: colorScheme.onErrorContainer,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: settings.translate('delete'),
                  onPressed: () {
                    if (historyProvider.historyEntries.isNotEmpty) {
                      _showDeleteAllDialog(historyProvider, settings);
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      body: _showAnalytics
        ? const AnalyticsScreen()
        : historyProvider.isLoading
            ? _buildLoadingScreen(settings)
            : (historyProvider.historyEntries.isEmpty)
                ? _buildEmptyHistory(settings)
                : (filteredEntries.isEmpty)
                    ? _buildNoSearchResults(settings)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryEntryCard(filteredEntries[index], historyProvider, settings);
                        },
                      ),
    );
  }

  void _showFilterDialog(BuildContext context, SettingsProvider settings) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(settings.translate('filter_sort'), style: textTheme.titleLarge),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settings.translate('sort_order'), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(settings.translate('newest'), style: textTheme.labelMedium),
                          selected: !_sortAscending,
                          onSelected: (b) => setDialogState(() => _sortAscending = false),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: Text(settings.translate('oldest'), style: textTheme.labelMedium),
                          selected: _sortAscending,
                          onSelected: (b) => setDialogState(() => _sortAscending = true),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(settings.translate('date_range'), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        if (_startDate != null || _endDate != null)
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(settings.translate('clear_dates'), style: textTheme.labelMedium),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _startDate == null ? settings.translate('start_date') : _formatDateShort(_startDate!),
                            style: textTheme.bodyMedium,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setDialogState(() => _startDate = picked);
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _endDate == null ? settings.translate('end_date') : _formatDateShort(_endDate!),
                            style: textTheme.bodyMedium,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setDialogState(() => _endDate = picked);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Text(settings.translate('contains_class'), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filterOptions.map((cls) {
                        final isSelected = _selectedFilterClasses.contains(cls);

                        String label = cls;
                        if (cls == 'No Detections') label = settings.translate('no_detections');

                        return FilterChip(
                          label: Text(label, style: textTheme.labelMedium),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                _selectedFilterClasses.add(cls);
                              } else {
                                _selectedFilterClasses.remove(cls);
                              }
                            });
                          },
                          checkmarkColor: _getClassColor(cls),
                          selectedColor: cls == 'No Detections'
                              ? Colors.grey.withAlpha(100)
                              : _getClassColor(cls).withAlpha(100),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _selectedFilterClasses.clear();
                      _sortAscending = false;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(settings.translate('reset_all'), style: textTheme.labelLarge),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Text(settings.translate('apply'), style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryEntryCard(HistoryEntry entry, HistoryProvider historyProvider, SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final detectionCount = entry.detections.length;
    final detectionLabel = detectionCount == 1
        ? settings.translate('detection_label')
        : settings.translate('detections_label');

    return GestureDetector(
      onTap: () {
        settings.playTapSound();
        context.read<NavigationProvider>().showHistoryDetail(entry);
      },
      child: Card(
        color: colorScheme.secondaryContainer,
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateFull(context, entry.date),
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withAlpha(180),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: colorScheme.onErrorContainer
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        settings.playTapSound();
                        _showDeleteDialog(entry, historyProvider, settings);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: File(entry.imagePath).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(
                              File(entry.imagePath),
                              fit: BoxFit.cover,
                              cacheWidth: 200,
                            ),
                          )
                        : Icon(Icons.image_not_supported_rounded, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${settings.translate('file_label')}: ${entry.originalFileName}",
                            style: textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              color: colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$detectionCount $detectionLabel',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildClassChips(entry.uniqueClasses, settings),
                      ],
                    ),
                  ),
                ],
              ),
              if (entry.detections.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetectionDetails(entry.detections),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassChips(List<String> classes, SettingsProvider settings) {
    final textTheme = Theme.of(context).textTheme;

    if (classes.isEmpty) {
      return Chip(
        label: Text(
          settings.translate('no_detections'),
          style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade400,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: classes.map((className) {
        final color = _getClassColor(className);
        return Chip(
          label: Text(
            className,
            style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: color,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }

  Widget _buildDetectionDetails(List<Detection> detections) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detections.take(3).map((detection) {
        final color = _getClassColor(detection.label);
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detection.label,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.withAlpha(220),
                  ),
                ),
              ),
              Text(
                '${(detection.confidence * 100).toStringAsFixed(0)}%',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingScreen(SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            settings.translate('history_loading'),
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: colorScheme.secondary.withAlpha(100)),
          const SizedBox(height: 24),
          Text(
            settings.translate('history_no_history'),
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            settings.translate('history_prompt'),
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            settings.translate('no_results'),
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Color _getClassColor(String label) {
    final cleanLabel = label.toUpperCase().trim();
    switch (cleanLabel) {
      case 'HEALTHY':
        return Colors.green;
      case 'BLACKPOD':
        return Colors.orange;
      case 'MIRID':
        return Colors.purple;
      case 'PODBORER':
        return Colors.brown;
      case 'NO DETECTIONS':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  void _showDeleteDialog(HistoryEntry entry, HistoryProvider historyProvider, SettingsProvider settings) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.translate('history_delete_title'), style: textTheme.titleLarge),
        content: Text(settings.translate('history_delete_confirm'), style: textTheme.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              settings.playTapSound();
              Navigator.of(context).pop();
            },
            child: Text(settings.translate('cancel'), style: textTheme.labelLarge),
          ),
          FilledButton.tonal(
            onPressed: () {
              settings.playTapSound();
              historyProvider.deleteHistoryEntry(entry.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: Text(settings.translate('delete'), style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(HistoryProvider historyProvider, SettingsProvider settings) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.translate('delete_all_title'), style: textTheme.titleLarge),
        content: Text(settings.translate('delete_all_confirm'), style: textTheme.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              settings.playTapSound();
              Navigator.of(context).pop();
            },
            child: Text(settings.translate('cancel'), style: textTheme.labelLarge),
          ),
          FilledButton(
            onPressed: () {
              settings.playTapSound();
              historyProvider.clearAllHistory();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(settings.translate('delete_all_button'), style: textTheme.labelLarge?.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}