import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/tracked_file.dart';
import '../services/file_scanner_service.dart';

class FileDetailScreen extends StatelessWidget {
  final TrackedFile file;

  const FileDetailScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  _buildInfo(context, 'Size', file.sizeString, Icons.storage),
                  _buildInfo(context, 'Age', file.ageString, Icons.schedule),
                  _buildInfo(context, 'Created', file.formattedDate, Icons.calendar_today),
                  _buildInfo(context, 'Type', file.type.toString().split('.').last.toUpperCase(), Icons.category),
                  const SizedBox(height: 24),
                  if (file.isOld || file.isLarge) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              file.isOld && file.isLarge
                                  ? 'Old and large file. Consider deleting.'
                                  : file.isOld
                                      ? 'File is ${file.ageString} old.'
                                      : 'File uses ${file.sizeString}.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(file.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            width: double.infinity,
            height: 400,
            color: Colors.black,
            child: AssetEntityImage(snapshot.data!, isOriginal: false, fit: BoxFit.contain),
          );
        }
        return Container(
          width: double.infinity,
          height: 400,
          color: Colors.grey[300],
          child: Center(child: Icon(file.type == FileType.video ? Icons.videocam : Icons.photo, size: 64, color: Colors.grey[600])),
        );
      },
    );
  }

  Widget _buildInfo(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Delete this file? Cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final service = context.read<FileScannerService>();
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    final success = await service.deleteFile(file);

    if (context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete'), backgroundColor: Colors.red));
      }
    }
  }
}
