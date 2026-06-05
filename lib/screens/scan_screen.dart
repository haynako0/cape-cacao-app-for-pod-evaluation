import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';

enum ScanMode { gallery, camera }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  ScanMode _currentMode = ScanMode.gallery;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;
  double _baseScale = 1.0;
  
  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  
  FlashMode _currentFlashMode = FlashMode.off;
  
  bool _isFocusing = false;
  Offset? _focusPoint;
  
  bool _showGrid = false;
  
  late AnimationController _focusAnimationController;
  late Animation<double> _focusAnimation;

  final List<AssetEntity> _galleryImages = [];
  int _galleryPage = 0;
  bool _isLoadingGallery = true;
  bool _hasMoreToLoad = true;
  final int _galleryPageSize = 30;
  final ScrollController _galleryScrollController = ScrollController();
  AssetEntity? _selectedImage;
  String? _galleryPermissionError;
  final ImagePicker _picker = ImagePicker();

  late final NavigationProvider _navProvider;

  @override
  void initState() {
    super.initState();
    _navProvider = context.read<NavigationProvider>();
    WidgetsBinding.instance.addObserver(this);
    _galleryScrollController.addListener(_scrollListener);

    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 70, end: 55).animate(
      CurvedAnimation(parent: _focusAnimationController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _currentMode == ScanMode.gallery) {
        _fetchGalleryImages();
      }
    });

    if (_currentMode == ScanMode.camera) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _navProvider.registerScanAction(null);
    _galleryScrollController.removeListener(_scrollListener);
    _galleryScrollController.dispose();
    _cameraController?.dispose();
    _focusAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scanSelectedImage() async {
    if (_selectedImage == null) return;
    context.read<SettingsProvider>().playTapSound();
    final file = await _selectedImage!.file;
    if (file != null && mounted) {
      final imageBytes = await file.readAsBytes();
      final String fileName = _selectedImage!.title ?? 'image.jpg';
      _navProvider.showResult(imageBytes, fileName: fileName);
      setState(() => _selectedImage = null);
    }
  }

  Future<void> _pickAndScanImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      context.read<SettingsProvider>().playTapSound();
      final imageBytes = await image.readAsBytes();
      _navProvider.showResult(imageBytes, fileName: image.name);
    }
  }

  Future<void> _fetchGalleryImages() async {
    if (!_hasMoreToLoad) return;
    if (mounted) setState(() => _isLoadingGallery = true);
    
    PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      var status = await Permission.photos.request();
      if (status.isGranted) ps = PermissionState.authorized;
    }

    if (ps.isAuth) {
      if (mounted) setState(() => _galleryPermissionError = null);
      try {
        final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
        if (albums.isNotEmpty) {
          final images = await albums.first.getAssetListPaged(
            page: _galleryPage,
            size: _galleryPageSize,
          );
          if (mounted) {
            setState(() {
              _galleryImages.addAll(images);
              _galleryPage++;
              _isLoadingGallery = false;
              _hasMoreToLoad = images.length == _galleryPageSize;
            });
          }
        }
      } catch (e) {
         if (mounted) setState(() { _isLoadingGallery = false; _galleryPermissionError = "Could not load photos."; });
      }
    } else {
      if (mounted) setState(() { _isLoadingGallery = false; _galleryPermissionError = "Permission needed."; });
    }
  }

  void _scrollListener() {
    if (_galleryScrollController.position.pixels == _galleryScrollController.position.maxScrollExtent && !_isLoadingGallery) {
      _fetchGalleryImages();
    }
  }

  void _onImageSelected(AssetEntity image) {
    setState(() {
      _selectedImage = (_selectedImage == image) ? null : image;
    });
    context.read<SettingsProvider>().playTapSound();
  }

  void _openAppSettings() => openAppSettings();
  
  Future<void> _captureAndScanImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    context.read<SettingsProvider>().playTapSound();

    try {
      if (_cameraController!.value.focusPointSupported) {
        await _cameraController!.setFocusMode(FocusMode.locked);
        await _cameraController!.setExposureMode(ExposureMode.locked);
      }

      final XFile image = await _cameraController!.takePicture();
      
      if (_cameraController!.value.focusPointSupported) {
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setExposureMode(ExposureMode.auto);
      }

      final imageBytes = await image.readAsBytes();

      try {
        final String fileName = 'CAPE_${DateTime.now().millisecondsSinceEpoch}';
        await PhotoManager.editor.saveImage(
          imageBytes, 
          title: fileName,
          filename: '$fileName.jpg', 
          relativePath: "Pictures/CAPE Pictures" 
        );
      } catch (e) {
        debugPrint("Error saving image: $e");
      }

      if (mounted) {
        _navProvider.showResult(imageBytes, fileName: image.name);
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;
    
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized && _currentMode == ScanMode.camera) {
         _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized) return;

    if (await Permission.camera.request().isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          backCamera, 
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg, 
        );

        try {
          await _cameraController!.initialize();
          
          _maxAvailableZoom = await _cameraController!.getMaxZoomLevel();
          _minAvailableZoom = await _cameraController!.getMinZoomLevel();
          _minExposureOffset = await _cameraController!.getMinExposureOffset();
          _maxExposureOffset = await _cameraController!.getMaxExposureOffset();
          
          await _cameraController!.setFlashMode(_currentFlashMode);
          await _cameraController!.setZoomLevel(_currentZoomLevel);

          if (mounted) setState(() => _isCameraInitialized = true);
        } catch (e) {
          debugPrint("Error initializing camera: $e");
        }
      }
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentZoomLevel;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (details.scale == 1.0) return; 

    double scale = _baseScale * details.scale;
    if (scale < _minAvailableZoom) scale = _minAvailableZoom;
    if (scale > _maxAvailableZoom) scale = _maxAvailableZoom;

    if (_cameraController != null) {
      await _cameraController!.setZoomLevel(scale);
      setState(() => _currentZoomLevel = scale);
    }
  }

  void _onTapFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_isCameraInitialized) return;

    final offset = details.localPosition;
    final double relativeX = offset.dx / constraints.maxWidth;
    final double relativeY = offset.dy / constraints.maxHeight;

    setState(() {
      _focusPoint = offset;
      _isFocusing = true;
    });
    
    _focusAnimationController.reset();
    _focusAnimationController.forward();

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      await _cameraController!.setExposureMode(ExposureMode.auto);
      
      await _cameraController!.setFocusPoint(Offset(relativeX, relativeY));
      await _cameraController!.setExposurePoint(Offset(relativeX, relativeY));
    } catch (e) {
      debugPrint("Focus Error: $e");
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isFocusing = false);
    });
  }

  Future<void> _setZoom(double zoom) async {
    if (_cameraController == null) return;
    final z = zoom.clamp(_minAvailableZoom, _maxAvailableZoom);
    await _cameraController!.setZoomLevel(z);
    setState(() => _currentZoomLevel = z);
  }

  Future<void> _setExposure(double exposure) async {
    if (_cameraController == null) return;
    final e = exposure.clamp(_minExposureOffset, _maxExposureOffset);
    await _cameraController!.setExposureOffset(e);
    setState(() => _currentExposureOffset = e);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    
    FlashMode newMode;
    switch (_currentFlashMode) {
      case FlashMode.off: newMode = FlashMode.torch; break;
      case FlashMode.torch: newMode = FlashMode.auto; break;
      case FlashMode.auto: newMode = FlashMode.off; break;
      default: newMode = FlashMode.off; break;
    }

    try {
      await _cameraController!.setFlashMode(newMode);
      setState(() => _currentFlashMode = newMode);
    } catch (e) {
      debugPrint("Flash Error: $e");
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off: return Icons.flash_off_rounded;
      case FlashMode.auto: return Icons.flash_auto_rounded;
      case FlashMode.torch: return Icons.highlight_rounded;
      default: return Icons.flash_off_rounded;
    }
  }

  Future<void> _onModeChanged(ScanMode newMode) async {
    if (_currentMode == newMode) return;
    context.read<SettingsProvider>().playTapSound();

    if (_currentMode == ScanMode.camera) {
      await _cameraController?.dispose();
      setState(() {
        _cameraController = null;
        _isCameraInitialized = false;
        _currentZoomLevel = 1.0;
        _currentExposureOffset = 0.0;
      });
    }
    
    setState(() => _currentMode = newMode);
    
    if (newMode == ScanMode.camera) {
      _initializeCamera();
    } else {
      setState(() => _selectedImage = null);
      if (_galleryImages.isEmpty) _fetchGalleryImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMode == ScanMode.camera && _isCameraInitialized) {
      _navProvider.registerScanAction(_captureAndScanImage);
    } else if (_selectedImage != null && _currentMode == ScanMode.gallery) {
      _navProvider.registerScanAction(_scanSelectedImage);
    } else {
      _navProvider.registerScanAction(null);
    }

    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        _buildModeSwitcher(colorScheme),
        if (_selectedImage != null && _currentMode == ScanMode.gallery)
          _buildScanPrompt(context),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentMode == ScanMode.camera
                ? _buildCameraView()
                : _buildGalleryView(),
          ),
        ),
      ],
    );
  }

  Widget _buildScanPrompt(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('scan_prompt'),
      width: double.infinity,
      color: colorScheme.tertiary.withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        settings.translate('scan_prompt'), 
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildModeSwitcher(ColorScheme colorScheme) {
    final settings = context.watch<SettingsProvider>();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          _buildModeButton(settings.translate('gallery'), Icons.image_rounded, ScanMode.gallery, colorScheme),
          _buildModeButton(settings.translate('camera'), Icons.camera_alt_rounded, ScanMode.camera, colorScheme),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, IconData icon, ScanMode mode, ColorScheme colorScheme) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.tertiary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
              const SizedBox(width: 8),
              Text(text,
                  style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryView() {
    final settings = context.watch<SettingsProvider>();

    if (_galleryPermissionError != null) {
      return Center(
        key: const ValueKey('gallery_permission_denied'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(settings.translate('permission_needed')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _openAppSettings, child: Text(settings.translate('open_settings'))),
          ],
        ),
      );
    }
    if (_isLoadingGallery && _galleryImages.isEmpty) {
      return const Center(key: ValueKey('gallery_loading'), child: CircularProgressIndicator());
    }

    final int itemCount = _galleryImages.length + 1 + (_hasMoreToLoad ? 1 : 0);

    return Padding(
      key: const ValueKey('gallery_view'),
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        controller: _galleryScrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) return _buildFilePickerButton();
          if (index == _galleryImages.length + 1) return const Center(child: CircularProgressIndicator());
          final asset = _galleryImages[index - 1];
          return GestureDetector(
            onTap: () => _onImageSelected(asset),
            child: GalleryImageTile(asset: asset, isSelected: _selectedImage == asset),
          );
        },
      ),
    );
  }

  Widget _buildFilePickerButton() {
    final settings = context.watch<SettingsProvider>();
    return GestureDetector(
      onTap: _pickAndScanImage,
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded, size: 36),
            const SizedBox(height: 4),
            Text(settings.translate('choose_file'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (_cameraController == null || !_isCameraInitialized) {
      return Center(
        key: const ValueKey('camera_initializing'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(settings.translate('initializing_camera'), style: TextStyle(color: colorScheme.primary)),
          ],
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onTapDown: (details) => _onTapFocus(details, constraints),
                child: CameraPreview(_cameraController!),
              ),

              if (_showGrid) _buildGridOverlay(),

              if (_isFocusing && _focusPoint != null)
                Positioned(
                  top: _focusPoint!.dy - 40,
                  left: _focusPoint!.dx - 40,
                  child: AnimatedBuilder(
                    animation: _focusAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        child: Container(
                          width: _focusAnimation.value,
                          height: _focusAnimation.value,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.greenAccent, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              Positioned(
                right: 8,
                top: 100,
                bottom: 100,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SizedBox(
                    height: 40,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Colors.yellow,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.yellow,
                      ),
                      child: Slider(
                        value: _currentExposureOffset,
                        min: _minExposureOffset,
                        max: _maxExposureOffset,
                        onChanged: _setExposure,
                      ),
                    ),
                  ),
                ),
              ),
              if (_currentExposureOffset != 0)
                Positioned(
                  right: 40,
                  top: MediaQuery.of(context).size.height / 2,
                  child: const Icon(Icons.wb_sunny_rounded, color: Colors.yellow, size: 20),
                ),

              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassIconButton(
                      icon: _showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                      onPressed: () => setState(() => _showGrid = !_showGrid),
                    ),
                    _buildGlassIconButton(
                      icon: _getFlashIcon(),
                      color: _currentFlashMode == FlashMode.off ? Colors.white : Colors.yellow,
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildZoomButton(1.0),
                        const SizedBox(width: 16),
                        _buildZoomButton(2.0),
                        if (_maxAvailableZoom >= 5.0) ...[
                          const SizedBox(width: 16),
                          _buildZoomButton(5.0),
                        ]
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.zoom_out_rounded, color: Colors.white70, size: 20),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: _currentZoomLevel,
                              min: _minAvailableZoom,
                              max: _maxAvailableZoom,
                              onChanged: _setZoom,
                            ),
                          ),
                        ),
                        const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                    Text(
                      "${_currentZoomLevel.toStringAsFixed(1)}x",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4)]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: GridPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, Color color = Colors.white, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildZoomButton(double zoomValue) {
    final bool isSelected = (_currentZoomLevel - zoomValue).abs() < 0.1;
    return GestureDetector(
      onTap: () => _setZoom(zoomValue),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow.withValues(alpha: 0.8) : Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white54),
        ),
        child: Text(
          "${zoomValue.toInt()}x",
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);

    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GalleryImageTile extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;

  const GalleryImageTile({
    super.key,
    required this.asset,
    required this.isSelected,
  });

  @override
  State<GalleryImageTile> createState() => _GalleryImageTileState();
}

class _GalleryImageTileState extends State<GalleryImageTile> {
  Uint8List? _thumbnailBytes;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(250, 250),
      format: ThumbnailFormat.jpeg,
      quality: 85,
    );
    if (mounted) {
      setState(() {
        _thumbnailBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_thumbnailBytes == null) {
      return Container(color: colorScheme.surfaceContainerHighest);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_thumbnailBytes!, fit: BoxFit.cover),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.isSelected ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              border: Border.all(
                color: colorScheme.tertiary,
                width: 3,
              ),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: colorScheme.primary, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}