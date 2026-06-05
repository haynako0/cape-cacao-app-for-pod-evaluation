import '../onnx_service.dart';

class HistoryEntry {
  final String id;
  final DateTime date;
  final String imagePath;
  final List<Detection> detections;
  final Map<String, Map<String, int>> selectedJsonIndices;
  final String originalFileName;
  final String? modelName;

  HistoryEntry({
    required this.id,
    required this.date,
    required this.imagePath,
    required this.detections,
    required this.selectedJsonIndices,
    required this.originalFileName,
    this.modelName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'originalFileName': originalFileName,
      'detections': detections.map((d) => _detectionToMap(d)).toList(),
      'selectedJsonIndices': selectedJsonIndices,
      'modelName': modelName,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawIndices = map['selectedJsonIndices'] as Map<String, dynamic>;

    final typedIndices = rawIndices.map(
      (classKey, innerMapData) {
        final typedInnerMap = Map<String, int>.from(innerMapData as Map);
        return MapEntry(classKey, typedInnerMap);
      },
    );

    String? loadedModelName = map['modelName'];
    if (loadedModelName != null && loadedModelName.contains('v2')) {
      loadedModelName = 'v1 (No Borer)';
    }

    return HistoryEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      imagePath: map['imagePath'],
      originalFileName: map['originalFileName'] ?? 'image.jpg',
      detections: (map['detections'] as List).map((d) => _detectionFromMap(d)).toList(),
      selectedJsonIndices: typedIndices,
      modelName: loadedModelName,
    );
  }

  static Map<String, dynamic> _detectionToMap(Detection detection) {
    return {
      'left': detection.left,
      'top': detection.top,
      'width': detection.width,
      'height': detection.height,
      'label': detection.label,
      'confidence': detection.confidence,
    };
  }

  static Detection _detectionFromMap(Map<String, dynamic> map) {
    return Detection(
      map['left'],
      map['top'],
      map['width'],
      map['height'],
      map['label'],
      map['confidence'],
    );
  }

  List<String> get uniqueClasses {
    return detections.map((d) => d.label).toSet().toList();
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}