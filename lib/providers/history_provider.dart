import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/history_entry.dart';
import '../onnx_service.dart';

class HistoryProvider with ChangeNotifier {
  List<HistoryEntry> _historyEntries = [];
  bool _isLoading = false;

  List<HistoryEntry> get historyEntries => _historyEntries;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    _loadHistory();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/history.json');
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);

        _historyEntries = [];
        
        for (final entryMap in jsonList) {
          try {
            final entry = HistoryEntry.fromMap(entryMap as Map<String, dynamic>);
            _historyEntries.add(entry);
          } catch (e) {
            debugPrint(e.toString());
          }
        }

        _historyEntries.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    try {
      final file = await _localFile;
      final jsonList = _historyEntries.map((entry) => entry.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> addHistoryEntry({
    required Uint8List imageBytes,
    required List<Detection> detections,
    required Map<String, Map<String, int>> selectedJsonIndices,
    required String originalFileName,
    required String modelName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final imagePath = '${directory.path}/$id.jpg';

    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(imageBytes);

    final newEntry = HistoryEntry(
      id: id,
      date: DateTime.now(),
      imagePath: imagePath,
      detections: detections,
      selectedJsonIndices: selectedJsonIndices,
      originalFileName: originalFileName,
      modelName: modelName,
    );

    _historyEntries.insert(0, newEntry);
    notifyListeners();
    await _saveHistory();
  }

  Future<void> deleteHistoryEntry(String id) async {
    final entry = _historyEntries.firstWhere((entry) => entry.id == id);
    final imageFile = File(entry.imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }

    _historyEntries.removeWhere((entry) => entry.id == id);
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearAllHistory() async {
    for (final entry in _historyEntries) {
      final imageFile = File(entry.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }

    _historyEntries.clear();
    notifyListeners();
    await _saveHistory();
  }

  List<HistoryEntry> getEntriesByClass(String className) {
    return _historyEntries.where((entry) =>
      entry.detections.any((detection) => detection.label == className)
    ).toList();
  }

  List<HistoryEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return _historyEntries.where((entry) =>
      entry.date.isAfter(start) && entry.date.isBefore(end)
    ).toList();
  }
}