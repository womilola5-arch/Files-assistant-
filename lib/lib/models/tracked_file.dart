import 'package:intl/intl.dart';

enum FileType { photo, video, screenshot, document, download, other }

class TrackedFile {
  final String id;
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime createdDate;
  final DateTime? lastAccessedDate;
  final FileType type;
  final String? thumbnailPath;
  bool isMarkedForDeletion;
  
  TrackedFile({
    required this.id,
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.createdDate,
    this.lastAccessedDate,
    required this.type,
    this.thumbnailPath,
    this.isMarkedForDeletion = false,
  });
  
  int get ageInMonths {
    final now = DateTime.now();
    return ((now.difference(createdDate).inDays) / 30).floor();
  }
  
  String get ageString {
    final months = ageInMonths;
    if (months == 0) return 'Less than a month';
    if (months == 1) return '1 month';
    if (months < 12) return '$months months';
    final years = (months / 12).floor();
    if (years == 1) return '1 year';
    return '$years years';
  }
  
  String get sizeString {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdDate);
  bool get isOld => ageInMonths >= 6;
  bool get isLarge => sizeBytes >= 50 * 1024 * 1024;
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'sizeBytes': sizeBytes,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'lastAccessedDate': lastAccessedDate?.millisecondsSinceEpoch,
      'type': type.index,
      'thumbnailPath': thumbnailPath,
      'isMarkedForDeletion': isMarkedForDeletion ? 1 : 0,
    };
  }
  
  factory TrackedFile.fromMap(Map<String, dynamic> map) {
    return TrackedFile(
      id: map['id'] as String,
      path: map['path'] as String,
      name: map['name'] as String,
      sizeBytes: map['sizeBytes'] as int,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate'] as int),
      lastAccessedDate: map['lastAccessedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastAccessedDate'] as int)
          : null,
      type: FileType.values[map['type'] as int],
      thumbnailPath: map['thumbnailPath'] as String?,
      isMarkedForDeletion: (map['isMarkedForDeletion'] as int) == 1,
    );
  }
}
