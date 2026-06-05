import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SfxService {
  final List<FlutterSoundPlayer> _players = [];
  static const int _poolSize = 8;
  int _currentPlayerIndex = 0;

  bool _isInitialized = false;

  String? _tap1Path;
  String? _tap2Path;
  String? _tap3Path;
  String? _complete1Path;
  String? _complete2Path;
  String? _complete3Path;

  Future<void> init() async {
    try {
      for (int i = 0; i < _poolSize; i++) {
        final player = FlutterSoundPlayer();
        player.setLogLevel(Level.off);
        await player.openPlayer();
        _players.add(player);
      }

      final tempDir = await getTemporaryDirectory();

      _tap1Path = await _extractAssetToFile('assets/audio/tap1.mp3', tempDir);
      _tap2Path = await _extractAssetToFile('assets/audio/tap2.mp3', tempDir);
      _tap3Path = await _extractAssetToFile('assets/audio/tap3.mp3', tempDir);
      
      _complete1Path = await _extractAssetToFile('assets/audio/complete1.mp3', tempDir);
      _complete2Path = await _extractAssetToFile('assets/audio/complete2.mp3', tempDir);
      _complete3Path = await _extractAssetToFile('assets/audio/complete3.mp3', tempDir);

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing SFX Service: $e");
      }
    }
  }

  Future<String> _extractAssetToFile(String assetPath, Directory tempDir) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final file = File('${tempDir.path}/${assetPath.split('/').last}');
      await file.writeAsBytes(byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ));
      return file.path;
    } catch (e) {
      rethrow; 
    }
  }

  void play(String sfxName) {
    if (sfxName == 'Vibration') {
      HapticFeedback.lightImpact(); 
      return;
    }

    if (!_isInitialized) {
      return;
    }

    String? filePath;

    switch (sfxName) {
      case 'Tap 1':
        filePath = _tap1Path;
        break;
      case 'Tap 2':
        filePath = _tap2Path;
        break;
      case 'Tap 3':
        filePath = _tap3Path;
        break;
      case 'Complete 1':
        filePath = _complete1Path;
        break;
      case 'Complete 2':
        filePath = _complete2Path;
        break;
      case 'Complete 3':
        filePath = _complete3Path;
        break;
      case 'Vibration (Long)': 
         _triggerLongVibration();
         return;
    }

    if (filePath != null && File(filePath).existsSync()) {
      final player = _players[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
      _startPlayback(player, filePath);
    }
  }
  
  void _triggerLongVibration() async {
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.vibrate();
  }

  Future<void> _startPlayback(FlutterSoundPlayer player, String filePath) async {
    try {
      if (player.isPlaying) {
        return;
      }
      await player.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
      );
    } catch (e) {
      debugPrint("Error starting playback: $e");
    }
  }

  Future<void> dispose() async {
    for (final player in _players) {
      try {
        await player.stopPlayer();
        await player.closePlayer();
      } catch (e) {
        debugPrint("Error disposing player: $e");
      }
    }
    _players.clear();
  }
}