import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import '../models/history_entry.dart'; 

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0; 
  final List<int> _pageHistory = [0];

  VoidCallback? _primaryScanAction;
  bool _isScanReady = false;
  
  Uint8List? _resultImageBytes;
  String? _resultImageFileName; 
  
  HistoryEntry? _viewingHistoryEntry;

  int get currentIndex => _currentIndex;
  VoidCallback? get primaryScanAction => _primaryScanAction;
  bool get isScanReady => _isScanReady;

  Uint8List? get resultImageBytes => _resultImageBytes;
  String? get resultImageFileName => _resultImageFileName; 
  
  HistoryEntry? get viewingHistoryEntry => _viewingHistoryEntry;

  bool handleBackPress() {
    if (_resultImageBytes != null || _viewingHistoryEntry != null) {
      hideResult();
      return true;
    }

    if (_pageHistory.length > 1) {
      _pageHistory.removeLast();
      _currentIndex = _pageHistory.last;
      notifyListeners();
      return true;
    }

    return false;
  }

  void changePage(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _pageHistory.add(index);
      notifyListeners();
    }
  }

  void registerScanAction(VoidCallback? action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newScanReadyState = action != null;
      if (_isScanReady != newScanReadyState) {
        _isScanReady = newScanReadyState;
        _primaryScanAction = action;
        notifyListeners();
      } else {
        _primaryScanAction = action;
      }
    });
  }

  void showResult(Uint8List imageBytes, {String? fileName}) { 
    _resultImageBytes = imageBytes;
    _resultImageFileName = fileName; 
    _viewingHistoryEntry = null; 
    notifyListeners();
  }

  void showHistoryDetail(HistoryEntry entry) {
    _viewingHistoryEntry = entry;
    _resultImageBytes = null; 
    _resultImageFileName = null; 
    notifyListeners();
  }

  void hideResult() {
    _resultImageBytes = null;
    _resultImageFileName = null; 
    _viewingHistoryEntry = null; 
    notifyListeners();
  }
}