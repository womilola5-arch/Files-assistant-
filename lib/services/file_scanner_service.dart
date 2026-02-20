import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/tracked_file.dart';
import '../database/database_helper.dart';

class FileScannerService extends ChangeNotifier {
  bool _isScanning = false;
  double _scanProgress = 0.0;
  List<TrackedFile> _allFiles = [];
  List<TrackedFile> _oldFiles = [];
  List<TrackedFile> _largeFiles = [];
  String? _errorMessage;

  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  List<TrackedFile> get allFiles => _allFiles;
  List<TrackedFile> get oldFiles => _oldFiles;
  List<TrackedFile> get largeFiles => _largeFiles;
  String? get errorMessage => _errorMessage;

  Future<bool> requestPermissions() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps.hasAccess) return true;
    _errorMessage = 'Permission denied';
    notifyListeners();
    return false;
  }

  Future<void> scanFiles() async {
    if (_isScanning) return;
    _isScanning = true;
    _scanProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!await requestPermissions()) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      final albums = await PhotoManager.getAssetPathList(type: RequestType.common, hasAll: true);
      if (albums.isEmpty) {
        _errorMessage = 'No photos or videos found';
        _isScanning = false;
        notifyListeners();
        return;
      }

      await DatabaseHelper.instance.clearAll();
      int totalProcessed = 0;
      int totalAssets = 0;

      for (final album in albums) {
        totalAssets += await album.assetCountAsync;
      }

      for (final album in albums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        for (final asset in assets) {
          final file = await _createTrackedFile(asset);
          if (file != null) await DatabaseHelper.instance.insert(file);
          totalProcessed++;
          _scanProgress = totalProcessed / totalAssets;
          if (totalProcessed % 50 == 0) notifyListeners();
        }
      }

      await loadFiles();
      _scanProgress = 1.0;
    } catch (e) {
      _errorMessage = 'Scan error: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<TrackedFile?> _createTrackedFile(asset) async {
    try {
      final file = await asset.file;
      if (file == null) return null;

      FileType fileType;
      if (asset.type == AssetType.video) {
        fileType = FileType.video;
      } else if (asset.title?.toLowerCase().contains('screenshot') ?? false) {
        fileType = FileType.screenshot;
      } else {
        fileType = FileType.photo;
      }

      return TrackedFile(
        id: asset.id,
        path: file.path,
        name: asset.title ?? 'Untitled',
        sizeBytes: await file.length(),
        createdDate: asset.createDateTime,
        lastAccessedDate: asset.modifiedDateTime,
        type: fileType,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> loadFiles() async {
    try {
      _allFiles = await DatabaseHelper.instance.getAllFiles();
      _oldFiles = await DatabaseHelper.instance.getOldFiles(monthsOld: 6);
      _largeFiles = await DatabaseHelper.instance.getLargeFiles(minSizeMB: 50);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading files: $e';
      notifyListeners();
    }
  }

  Future<bool> deleteFile(TrackedFile file) async {
    try {
      final asset = await AssetEntity.fromId(file.id);
      if (asset != null) {
        final result = await PhotoManager.editor.deleteWithIds([asset.id]);
        if (result.isNotEmpty) {
          await DatabaseHelper.instance.delete(file.id);
          await loadFiles();
          return true;
        }
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error deleting: $e';
      notifyListeners();
      return false;
    }
  }

  Future<int> deleteMultipleFiles(List<TrackedFile> files) async {
    try {
      final ids = files.map((f) => f.id).toList();
      final result = await PhotoManager.editor.deleteWithIds(ids);
      await DatabaseHelper.instance.deleteMultiple(ids);
      await loadFiles();
      return result.length;
    } catch (e) {
      _errorMessage = 'Error deleting: $e';
      notifyListeners();
      return 0;
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    final totalSize = await DatabaseHelper.instance.getTotalStorageUsed();
    final fileCount = await DatabaseHelper.instance.getFileCount();
    final oldFilesSize = _oldFiles.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    final largeFilesSize = _largeFiles.fold<int>(0, (sum, file) => sum + file.sizeBytes);

    return {
      'totalSize': totalSize,
      'fileCount': fileCount,
      'oldFilesCount': _oldFiles.length,
      'oldFilesSize': oldFilesSize,
      'largeFilesCount': _largeFiles.length,
      'largeFilesSize': largeFilesSize,
    };
  }
}
