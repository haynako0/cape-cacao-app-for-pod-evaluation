import 'dart:async'; 
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart'; 
import '../providers/navigation_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../models/history_entry.dart';
import '../onnx_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  List<Detection>? _detections;
  Uint8List? _imageBytes;
  OnnxService? _onnxService;
  
  Size? _originalImageSize;
  Detection? _selectedDetection;
  
  Map<String, dynamic> _cocoaInfoData = {};
  bool _isInfoLoaded = false;
  
  Map<String, Map<String, int>> _currentJsonIndices = {};
  String _originalFileName = 'image.jpg';

  ui.Image? _decodedUiImage;
  bool _showSavedNotification = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _loadCocoaInfo();
  }

  Future<void> _loadData() async {
    final navProvider = context.read<NavigationProvider>();
    final historyEntry = navProvider.viewingHistoryEntry;
    final newImageBytes = navProvider.resultImageBytes;

    if (historyEntry != null) {
      await _loadDataFromHistory(historyEntry);
    } else if (newImageBytes != null) {
      _imageBytes = newImageBytes; 
      if (navProvider.resultImageFileName != null) {
        _originalFileName = navProvider.resultImageFileName!;
      }
      await _runInferenceOnNewImage();
    }
  }

  Future<void> _loadDataFromHistory(HistoryEntry entry) async {
    final file = File(entry.imagePath);
    if (!await file.exists()) {
      setState(() => _isLoading = false);
      return;
    }

    final bytes = await file.readAsBytes();
    final decodedImage = await decodeImageFromList(bytes);
    
    if (mounted) {
      setState(() {
        _decodedUiImage = decodedImage;
        _imageBytes = bytes; 
        _originalImageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        _detections = entry.detections;
        _currentJsonIndices = entry.selectedJsonIndices;
        _originalFileName = entry.originalFileName;
        _isLoading = false;
        if (entry.detections.isNotEmpty) {
          _selectedDetection = entry.detections.first;
        }
      });
    }
  }

  Future<void> _loadCocoaInfo() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/cocoa_info.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _cocoaInfoData = jsonData;
        _isInfoLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading cocoa info JSON: $e');
      setState(() {
        _cocoaInfoData = {};
        _isInfoLoaded = true;
      });
    }
  }

  Map<String, Map<String, int>> _generateSelectedJsonIndices(List<Detection> detections) {
    final indices = <String, Map<String, int>>{};
    
    for (final detection in detections) {
      final cleanLabel = detection.label.toUpperCase().trim();
      final sectionIndices = <String, int>{};
      
      final sections = ['condition_overview', 'detailed_analysis', 'prevention_management', 'additional_information'];
      for (final section in sections) {
        final seed = DateTime.now().millisecondsSinceEpoch + detection.label.hashCode + section.hashCode;
        sectionIndices[section] = seed % 3;
      }
      
      indices[cleanLabel] = sectionIndices;
    }
    
    return indices;
  }

  String _getJsonText(String label, String section) {
    if (!_isInfoLoaded) {
      return 'Loading information...';
    }
    
    final settings = context.read<SettingsProvider>();
    final currentLang = settings.selectedLanguage;

    final cleanLabel = label.toUpperCase().trim();
    try {
      if (_cocoaInfoData.containsKey(cleanLabel)) {
        final classData = _cocoaInfoData[cleanLabel];
        if (classData is Map && classData.containsKey(section)) {
          final sectionDataMap = classData[section];
          
          final List<dynamic> langSpecificList = sectionDataMap[currentLang] ?? sectionDataMap['English'] ?? [];

          if (langSpecificList.isNotEmpty) {
            int index;
            if (_currentJsonIndices.containsKey(cleanLabel) && 
                _currentJsonIndices[cleanLabel]!.containsKey(section)) {
              index = _currentJsonIndices[cleanLabel]![section]! % langSpecificList.length;
            } else {
              index = 0;
            }
            return langSpecificList[index].toString();
          }
        }
      }
      return _getFallbackText(section);
    } catch (e) {
      debugPrint('Error getting JSON text: $e');
      return _getFallbackText(section);
    }
  }

  String _getFallbackText(String section) {
    return 'Information not available at this time.';
  }

  Future<void> _runInferenceOnNewImage() async {
    final settings = context.read<SettingsProvider>();
    
    final imageBytes = _imageBytes!;
    final decodedImage = await decodeImageFromList(imageBytes);
    final trueWidth = decodedImage.width.toDouble();
    final trueHeight = decodedImage.height.toDouble();

    if (!mounted) return;

    setState(() {
      _decodedUiImage = decodedImage;
      _originalImageSize = Size(trueWidth, trueHeight);
    });

    String modelPath = 'assets/models/v1.onnx'; 
    String modelNameDisplay = 'v1 (No Borer)';

    


    _onnxService ??= await OnnxService.create(modelPath);
    
    if (_onnxService != null && _imageBytes != null) {
      final detections = await _onnxService!.runInference(
        _imageBytes!, 
        trueWidth, 
        trueHeight, 
        settings.confidenceThreshold
      );
      
      if (mounted) {
        final selectedJsonIndices = _generateSelectedJsonIndices(detections);
        
        context.read<SettingsProvider>().playScanSound();

        setState(() {
          _detections = detections;
          _currentJsonIndices = selectedJsonIndices;
          _isLoading = false;
          if (detections.isNotEmpty) {
            _selectedDetection = detections.first;
          }
        });

        final historyProvider = context.read<HistoryProvider>();
        await historyProvider.addHistoryEntry(
          imageBytes: _imageBytes!,
          detections: detections,
          selectedJsonIndices: selectedJsonIndices,
          originalFileName: _originalFileName,
          modelName: modelNameDisplay, 
        );
      }
    }
  }

  Color _getClassColor(String label) {
    final cleanLabel = label.toUpperCase().trim();
    switch (cleanLabel) {
      case 'HEALTHY':
        return Colors.green;
      case 'BLACKPOD':
        return Colors.orange.shade800;
      case 'MIRID':
        return Colors.purple; 
      case 'PODBORER':
        return Colors.brown;
      default:
        return Colors.red;
    }
  }

  IconData _getClassIcon(String label) {
    final cleanLabel = label.toUpperCase().trim();
    switch (cleanLabel) {
      case 'HEALTHY':
        return Icons.check_circle_outline;
      case 'BLACKPOD':
        return Icons.warning_amber_rounded;
      case 'MIRID':
        return Icons.bug_report_outlined;
      case 'PODBORER':
        return Icons.pest_control_rounded;
      default:
        return Icons.help_outline;
    }
  }

  void _triggerSavedNotification() {
    if (!mounted) return;
    setState(() {
      _showSavedNotification = true;
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSavedNotification = false;
        });
      }
    });
  }

  String _getThemeLogoPath(int index) {
    switch (index) {
      case 1: return 'assets/images/header_icon_pink.png'; 
      case 2: return 'assets/images/header_icon_blue.png'; 
      case 3: return 'assets/images/header_icon_green.png'; 
      case 0: 
      default: return 'assets/images/header_icon_purple.png'; 
    }
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final list = Uint8List.view(data.buffer);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(list, (img) => completer.complete(img));
    return completer.future;
  }

  Future<void> _saveResultImageWithBoxes(BuildContext context) async {
    if (_decodedUiImage == null || _detections == null) return;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(_decodedUiImage!.width.toDouble(), _decodedUiImage!.height.toDouble());

      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        image: _decodedUiImage!,
        fit: BoxFit.cover,
      );

      for (var detection in _detections!) {
        final color = _getClassColor(detection.label);
        
        final rect = Rect.fromLTWH(
          detection.left,
          detection.top,
          detection.width,
          detection.height,
        );
        
        final boxPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.005; 
          
        canvas.drawRect(rect, boxPaint);

        final text = ' ${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}% ';
        final fontSize = size.width * 0.03; 

        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        var textOffset = Offset(rect.left, rect.top - textPainter.height);
        if (textOffset.dy < 0) {
          textOffset = Offset(rect.left, rect.top + boxPaint.strokeWidth);
        }

        final bgRect = Rect.fromLTWH(
          textOffset.dx, 
          textOffset.dy, 
          textPainter.width, 
          textPainter.height
        ).inflate(4);

        final bgPaint = Paint()..color = color;
        canvas.drawRect(bgRect, bgPaint);
        textPainter.paint(canvas, textOffset);
      }

      final settings = context.read<SettingsProvider>();
      final themeIndex = settings.selectedThemeIndex;
      final logoPath = _getThemeLogoPath(themeIndex);
      final logoImage = await _loadUiImage(logoPath);

      final now = DateTime.now();
      final dateStr = "${now.month.toString().padLeft(2,'0')}/${now.day.toString().padLeft(2,'0')}/${now.year}";
      
      final baseFontSize = size.width * 0.007;
      final logoTargetSize = size.width * 0.05; 
      final padding = size.width * 0.0001; 
      final gap = size.width * 0.001;

      final bottomY = size.height - padding - logoTargetSize;

      final srcRect = Rect.fromLTWH(
        0, 0, 
        logoImage.width.toDouble(), 
        logoImage.height.toDouble()
      );
      
      final dstRect = Rect.fromLTWH(
        padding, 
        bottomY, 
        logoTargetSize, 
        logoTargetSize
      );

      final logoPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8);
      
      canvas.drawImageRect(logoImage, srcRect, dstRect, logoPaint);

      final capePainter = TextPainter(
        text: TextSpan(
          text: "CAPE",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: baseFontSize * 3.5, 
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            shadows: [
              Shadow(blurRadius: 2, color: Colors.black.withValues(alpha: 0.5), offset: const Offset(1, 1))
            ]
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final topTextPainter = TextPainter(
        text: TextSpan(
          text: "Cacao App for Pod Evaluation",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: baseFontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 2, color: Colors.black.withValues(alpha: 0.5), offset: const Offset(1, 1))
            ]
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bottomTextPainter = TextPainter(
        text: TextSpan(
          text: "$_originalFileName • $dateStr",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: baseFontSize * 0.85,
            fontWeight: FontWeight.normal,
            shadows: [
              Shadow(blurRadius: 2, color: Colors.black.withValues(alpha: 0.5), offset: const Offset(1, 1))
            ]
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final capeX = padding + logoTargetSize + gap;
      final capeY = bottomY + (logoTargetSize / 2) - (capePainter.height / 2);
      
      capePainter.paint(canvas, Offset(capeX, capeY));

      final stackX = capeX + capePainter.width + gap;
      
      final totalStackHeight = topTextPainter.height + bottomTextPainter.height + (gap / 2);
      final stackStartY = bottomY + (logoTargetSize / 2) - (totalStackHeight / 2);

      topTextPainter.paint(canvas, Offset(stackX, stackStartY));
      bottomTextPainter.paint(canvas, Offset(stackX, stackStartY + topTextPainter.height + (gap / 2)));

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) throw Exception("Failed to encode image");

      final pngBytes = byteData.buffer.asUint8List();

      final String fileName = 'CAPE_Analyzed_${DateTime.now().millisecondsSinceEpoch}';
      
      await PhotoManager.editor.saveImage(
        pngBytes,
        title: fileName,
        filename: '$fileName.png', 
        relativePath: "Pictures/CAPE Pictures", 
      );

      _triggerSavedNotification();

    } catch (e) {
      debugPrint("Error saving analyzed image: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          _isLoading || _imageBytes == null
              ? _buildLoadingScreen(settings, colorScheme)
              : _buildScrollableResultScreen(settings, colorScheme),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutBack,
            top: _showSavedNotification ? 16 : -80, 
            left: 20,
            right: 20,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.tertiary,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: colorScheme.onTertiary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "Saved to Gallery (CAPE Pictures)",
                      style: TextStyle(
                        color: colorScheme.onTertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(SettingsProvider settings, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            settings.translate('analyzing_image'), 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScrollableResultScreen(SettingsProvider settings, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(colorScheme),
            const SizedBox(height: 24),
            
            if (_detections != null && _detections!.isNotEmpty)
              _buildDetectionCountCard(settings, colorScheme)
            else if (_detections != null)
              _buildNoDetections(settings, colorScheme),
              
            const SizedBox(height: 24),
            
            if (_detections != null && _detections!.isNotEmpty)
              _buildDetectionDetailsSection(settings, colorScheme),
            
            const SizedBox(height: 32),

            

            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 340,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), 
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand, 
          children: [
            if (_imageBytes != null)
              Image.memory(
                _imageBytes!,
                fit: BoxFit.contain, 
                alignment: Alignment.center,
              ),
            
            if (_detections != null)
              CustomPaint(
                painter: _EnhancedBoundingBoxPainter(
                  detections: _detections!,
                  originalImageSize: _originalImageSize!,
                  selectedDetection: _selectedDetection,
                  getClassColor: _getClassColor,
                ),
              ),

            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                onPressed: () {
                   context.read<SettingsProvider>().playTapSound();
                  _saveResultImageWithBoxes(context);
                },
                heroTag: 'download_btn',
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                child: const Icon(Icons.download_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionCountCard(SettingsProvider settings, ColorScheme colorScheme) {
    final hasDetections = _detections != null && _detections!.isNotEmpty;
    final count = _detections!.length;
    final text = hasDetections 
        ? '$count ${count == 1 ? settings.translate('condition_detected') : settings.translate('conditions_detected')}'
        : settings.translate('no_conditions_detected_short');

    return Card(
      elevation: 2,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text, 
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            if (hasDetections && _detections!.length > 1)
              TextButton.icon(
                onPressed: () => setState(() => _selectedDetection = null),
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.4),
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: Text(
                  settings.translate('view_all'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ), 
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionDetailsSection(SettingsProvider settings, ColorScheme colorScheme) {
    if (_selectedDetection != null) {
      return _buildSelectedDetectionDetails(settings, colorScheme);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 12),
            child: Text(
              settings.translate('all_detections'), 
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _buildDetectionList(settings, colorScheme),
        ],
      );
    }
  }

  Widget _buildSelectedDetectionDetails(SettingsProvider settings, ColorScheme colorScheme) {
    final detection = _selectedDetection!;
    final color = _getClassColor(detection.label);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getClassIcon(detection.label), color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.label,
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.w800, 
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(detection.confidence * 100).toStringAsFixed(1)}% ${settings.translate('confidence')}',
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ), 
                    ],
                  ),
                ),
                if (_detections != null && _detections!.length > 1)
                  IconButton(
                    icon: Icon(Icons.list_rounded, size: 28, color: colorScheme.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                    onPressed: () => setState(() => _selectedDetection = null),
                    tooltip: settings.translate('view_all'),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        
        _buildInfoSection(
          title: settings.translate('condition_overview_title'), 
          content: _getJsonText(detection.label, 'condition_overview'),
          icon: Icons.menu_book_rounded,
          bgColor: colorScheme.tertiaryContainer, 
          iconColor: colorScheme.onTertiaryContainer,
          textColor: colorScheme.onTertiaryContainer,
        ),
        const SizedBox(height: 16),
        
        _buildInfoSection(
          title: settings.translate('detailed_analysis_title'), 
          content: _getJsonText(detection.label, 'detailed_analysis'),
          icon: Icons.analytics_rounded,
          bgColor: colorScheme.tertiaryContainer,
          iconColor: colorScheme.onTertiaryContainer,
          textColor: colorScheme.onTertiaryContainer,
        ),
        const SizedBox(height: 16),
        
        _buildInfoSection(
          title: settings.translate('prevention_title'), 
          content: _getJsonText(detection.label, 'prevention_management'),
          icon: Icons.shield_rounded,
          bgColor: colorScheme.tertiaryContainer, 
          iconColor: colorScheme.onTertiaryContainer,
          textColor: colorScheme.onTertiaryContainer,
        ),
        const SizedBox(height: 16),
        
        _buildInfoSection(
          title: settings.translate('additional_info_title'), 
          content: _getJsonText(detection.label, 'additional_information'),
          icon: Icons.info_rounded,
          bgColor: colorScheme.tertiaryContainer, 
          iconColor: colorScheme.onTertiaryContainer,
          textColor: colorScheme.onTertiaryContainer,
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Card(
      elevation: 2,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor, 
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: textColor.withValues(alpha: 0.86), 
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionList(SettingsProvider settings, ColorScheme colorScheme) {
    return Column(
      children: _detections!.map((detection) {
        final color = _getClassColor(detection.label);
        final isSelected = _selectedDetection == detection;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedDetection = detection),
          child: Card(
            elevation: isSelected ? 2 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected 
                  ? color.withValues(alpha: 0.08) 
                  : colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isSelected 
                  ? BorderSide(color: color, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getClassIcon(detection.label), color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detection.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(detection.confidence * 100).toStringAsFixed(1)}% ${settings.translate('confidence')}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded, 
                    color: isSelected ? color : colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoDetections(SettingsProvider settings, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              settings.translate('no_conditions_title'), 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: colorScheme.onSurface
              ),
            ),
            const SizedBox(height: 12),
            Text(
              settings.translate('no_conditions_body'), 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant, 
                height: 1.5,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedBoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size originalImageSize;
  final Detection? selectedDetection;
  final Color Function(String) getClassColor;

  _EnhancedBoundingBoxPainter({
    required this.detections,
    required this.originalImageSize,
    required this.selectedDetection,
    required this.getClassColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, originalImageSize, size);
    final Size destinationSize = fittedSizes.destination;
    final double dx = (size.width - destinationSize.width) / 2;
    final double dy = (size.height - destinationSize.height) / 2;
    final double scale = destinationSize.width / originalImageSize.width;
    
    for (var detection in detections) {
      final isSelected = selectedDetection == detection;
      final color = getClassColor(detection.label);
      
      final onScreenRect = Rect.fromLTWH(
        (detection.left * scale) + dx,
        (detection.top * scale) + dy,
        detection.width * scale,
        detection.height * scale,
      );
      
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 4.0 : 2.5;

      if (isSelected) {
         canvas.drawRect(onScreenRect, Paint()
          ..color = Colors.black.withValues(alpha: 0.4) 
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        );
      }

      canvas.drawRect(onScreenRect, boxPaint);

      final text = ' ${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}% ';
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSelected ? 14.0 : 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      
      var textOffset = Offset(onScreenRect.left, onScreenRect.top - textPainter.height - 4);
      if (textOffset.dy < 0) {
        textOffset = Offset(onScreenRect.left, onScreenRect.top + 4);
      }
      
      final backgroundRect = Rect.fromPoints(
        textOffset,
        textOffset + Offset(textPainter.width, textPainter.height),
      ).inflate(6);
      
      final backgroundPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      final roundedRect = RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8));
      canvas.drawRRect(roundedRect, backgroundPaint);
      
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
