import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class Detection {
  final double left;
  final double top;
  final double width;
  final double height;
  final String label;
  final double confidence;

  Detection(this.left, this.top, this.width, this.height, this.label, this.confidence);
}

class _PreprocessResult {
  final Float32List inputBytes;
  _PreprocessResult(this.inputBytes);
}

Future<_PreprocessResult> _convertBytesInIsolate(Uint8List rgbaBytes) async {
  final stopwatch = Stopwatch()..start();
  
  const int inputWidth = 640;
  const int inputHeight = 640;
  final int totalPixels = inputWidth * inputHeight;
  
  final inputBytes = Float32List(1 * 3 * inputWidth * inputHeight);
  
  int pixelIndex = 0;
  for (int i = 0; i < rgbaBytes.length; i += 4) {
    if (pixelIndex >= totalPixels) break;

    final double r = rgbaBytes[i] / 255.0;
    final double g = rgbaBytes[i + 1] / 255.0;
    final double b = rgbaBytes[i + 2] / 255.0;

    final int rIndex = pixelIndex;
    final int gIndex = pixelIndex + totalPixels;
    final int bIndex = pixelIndex + (2 * totalPixels);

    inputBytes[rIndex] = r;
    inputBytes[gIndex] = g;
    inputBytes[bIndex] = b;

    pixelIndex++;
  }
  
  stopwatch.stop();
  debugPrint('[PERF] Float32 Conversion in Isolate took: ${stopwatch.elapsedMilliseconds}ms');

  return _PreprocessResult(inputBytes);
}

class OnnxService {
  late final OrtSession _session;
  late final List<String> _labels;
  static const int _modelInputWidth = 640;
  static const int _modelInputHeight = 640;

  OnnxService._(this._session, this._labels);

  static Future<OnnxService?> create(String modelPath) async {
    final stopwatch = Stopwatch()..start();
    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();

      try {
        sessionOptions.setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
        sessionOptions.setIntraOpNumThreads(4);
      } catch (e) {
        debugPrint('[PERF] Warning: Optimization settings failed: $e');
      }

      final rawAssetFile = await rootBundle.load(modelPath);
      final bytes = rawAssetFile.buffer.asUint8List();

      final session = OrtSession.fromBuffer(bytes, sessionOptions);
      final labels = await _loadLabels('assets/labels.txt');
      
      stopwatch.stop();
      debugPrint('[PERF] Model Loaded ($modelPath) in: ${stopwatch.elapsedMilliseconds}ms');
      
      return OnnxService._(session, labels);
    } catch (e) {
      debugPrint("Error loading ONNX model ($modelPath): $e");
      return null;
    }
  }

  static Future<List<String>> _loadLabels(String assetPath) async {
    final labelData = await rootBundle.loadString(assetPath);
    return labelData.split('\n').where((label) => label.isNotEmpty).toList();
  }

  Future<List<Detection>> runInference(Uint8List imageBytes, double originalWidth, double originalHeight, double confidenceThreshold) async {
    final totalStopwatch = Stopwatch()..start();
    debugPrint('[PERF] Starting Inference Pipeline...');

    final compressStopwatch = Stopwatch()..start();
    final Uint8List resizedBytes = await FlutterImageCompress.compressWithList(
      imageBytes,
      minHeight: _modelInputHeight,
      minWidth: _modelInputWidth,
      quality: 90,
      format: CompressFormat.jpeg,
    );
    compressStopwatch.stop();
    debugPrint('[PERF] Native Resize took: ${compressStopwatch.elapsedMilliseconds}ms');

    final gpuStopwatch = Stopwatch()..start();
    
    final ui.Codec codec = await ui.instantiateImageCodec(resizedBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image gpuImage = frameInfo.image;

    final double scale = min(
      _modelInputWidth / gpuImage.width,
      _modelInputHeight / gpuImage.height,
    );
    
    final double drawWidth = gpuImage.width * scale;
    final double drawHeight = gpuImage.height * scale;
    
    final double padX = (_modelInputWidth - drawWidth) / 2;
    final double padY = (_modelInputHeight - drawHeight) / 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _modelInputWidth.toDouble(), _modelInputHeight.toDouble()), 
      Paint()..color = Colors.black
    );

    canvas.drawImageRect(
      gpuImage, 
      Rect.fromLTWH(0, 0, gpuImage.width.toDouble(), gpuImage.height.toDouble()), 
      Rect.fromLTWH(padX, padY, drawWidth, drawHeight), 
      Paint()..filterQuality = FilterQuality.medium
    );

    final ui.Image finalImage = await recorder.endRecording().toImage(_modelInputWidth, _modelInputHeight);
    
    final ByteData? rawData = await finalImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rawData == null) throw Exception("Failed to get byte data");
    
    final Uint8List rawRgbaBytes = rawData.buffer.asUint8List();
    
    gpuStopwatch.stop();
    debugPrint('[PERF] GPU Composition & Decode took: ${gpuStopwatch.elapsedMilliseconds}ms');

    final preProcessResult = await compute(_convertBytesInIsolate, rawRgbaBytes);
    final inputBytes = preProcessResult.inputBytes;
    
    final inputShape = [1, 3, _modelInputWidth, _modelInputHeight];
    final inputOrtValue = OrtValueTensor.createTensorWithDataList(inputBytes, inputShape);
    final inputs = {'images': inputOrtValue};
    final runOptions = OrtRunOptions();

    final inferenceStopwatch = Stopwatch()..start();
    final outputs = await _session.runAsync(runOptions, inputs);
    inferenceStopwatch.stop();
    debugPrint('[PERF] ONNX Session Run took: ${inferenceStopwatch.elapsedMilliseconds}ms');

    inputOrtValue.release();
    runOptions.release();

    if (outputs == null || outputs.isEmpty || outputs[0] == null) {
      return [];
    }

    final postProcessStopwatch = Stopwatch()..start();
    final detectionOutput = outputs[0]!.value as List<List<List<double>>>;
    List<Detection> detections = [];

    final int numBoxes = detectionOutput[0][0].length;
    final int numProperties = detectionOutput[0].length;
    final int numLabels = numProperties - 4;

    final double globalScale = min(
      _modelInputWidth / originalWidth,
      _modelInputHeight / originalHeight,
    );

    final double globalPadX = (_modelInputWidth - (originalWidth * globalScale)) / 2;
    final double globalPadY = (_modelInputHeight - (originalHeight * globalScale)) / 2;

    for (int i = 0; i < numBoxes; i++) {
      double maxClassScore = 0;
      int bestClassIndex = -1;

      for (int j = 0; j < numLabels; j++) {
        final score = detectionOutput[0][4 + j][i];
        if (score > maxClassScore) {
          maxClassScore = score;
          bestClassIndex = j;
        }
      }

      if (maxClassScore > confidenceThreshold) {
        if (bestClassIndex >= _labels.length) continue;

        final double xCenter = detectionOutput[0][0][i];
        final double yCenter = detectionOutput[0][1][i];
        final double w = detectionOutput[0][2][i];
        final double h = detectionOutput[0][3][i];

        final double x1 = xCenter - (w / 2);
        final double y1 = yCenter - (h / 2);
        final double x2 = xCenter + (w / 2);
        final double y2 = yCenter + (h / 2);

        final double unpaddedX1 = x1 - globalPadX;
        final double unpaddedY1 = y1 - globalPadY;
        final double unpaddedX2 = x2 - globalPadX;
        final double unpaddedY2 = y2 - globalPadY;

        double originX1 = unpaddedX1 / globalScale;
        double originY1 = unpaddedY1 / globalScale;
        double originX2 = unpaddedX2 / globalScale;
        double originY2 = unpaddedY2 / globalScale;

        originX1 = max(0, originX1);
        originY1 = max(0, originY1);
        originX2 = min(originalWidth, originX2);
        originY2 = min(originalHeight, originY2);

        final width = originX2 - originX1;
        final height = originY2 - originY1;

        if (width > 0 && height > 0) {
          detections.add(Detection(
            originX1,
            originY1,
            width,
            height,
            _labels[bestClassIndex],
            maxClassScore,
          ));
        }
      }
    }

    for (var element in outputs) {
      element?.release();
    }

    final result = _nonMaximumSuppression(detections);
    postProcessStopwatch.stop();
    totalStopwatch.stop();

    debugPrint('[PERF] Post-processing took: ${postProcessStopwatch.elapsedMilliseconds}ms');
    debugPrint('[PERF] TOTAL INFERENCE PIPELINE: ${totalStopwatch.elapsedMilliseconds}ms');

    return result;
  }

  List<Detection> _nonMaximumSuppression(List<Detection> detections, {double iouThreshold = 0.45}) {
    if (detections.isEmpty) return [];

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    final List<Detection> finalDetections = [];

    while (detections.isNotEmpty) {
      final bestDetection = detections.removeAt(0);
      finalDetections.add(bestDetection);

      final List<Detection> remaining = [];

      for (final detection in detections) {
        if (detection.label == bestDetection.label) {
          final iou = _calculateIoU(bestDetection, detection);
          if (iou < iouThreshold) {
            remaining.add(detection);
          }
        } else {
          remaining.add(detection);
        }
      }
      detections = remaining;
    }
    return finalDetections;
  }

  double _calculateIoU(Detection a, Detection b) {
    final ax1 = a.left;
    final ay1 = a.top;
    final ax2 = a.left + a.width;
    final ay2 = a.top + a.height;
    final bx1 = b.left;
    final by1 = b.top;
    final bx2 = b.left + b.width;
    final by2 = b.top + b.height;

    final x1 = max(ax1, bx1);
    final y1 = max(ay1, by1);
    final x2 = min(ax2, bx2);
    final y2 = min(ay2, by2);

    final intersectionWidth = x2 - x1;
    final intersectionHeight = y2 - y1;

    if (intersectionWidth <= 0 || intersectionHeight <= 0) return 0.0;

    final intersectionArea = intersectionWidth * intersectionHeight;
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final unionArea = areaA + areaB - intersectionArea;

    return intersectionArea / unionArea;
  }
}