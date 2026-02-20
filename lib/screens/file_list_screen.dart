import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/tracked_file.dart';
import '../services/file_scanner_service.dart';
import 'file_detail_screen.dart';

class FileListScreen extends StatefulWidget {
  final String title;
  final List<TrackedFile> files;

  const FileListScreen({super.key, required this.title, required this.files});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final Set<String> _selected = {};
  bool _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_selectionMode)
            TextButton(
              onPressed: () => setState(() {
                _selected.clear();
                _selectionMode = false;
              }),
              child: const Text('Cancel'),
            )
          else
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => setState(() => _selectionMode = true),
            ),
        ],
      ),
      body: widget.files.isEmpty ? _buildEmpty() : _buildList(),
      bottomNavigationBar: _selectionMode && _selected.isNotEmpty ? _buildBottom() : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No files here', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: widget.files.length,
      itemBuilder: (context, index) {
        final file = widget.files[index];
        final isSelected = _selected.contains(file.id);

        return ListTile(
          leading: _buildThumb(file),
          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${file.ageString} • ${file.sizeString}'),
          trailing: _selectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (v) => setState(() {
                    if (v == true) _selected.add(file.id); else _selected.remove(file.id);
                  }),
                )
              : Icon(file.type == FileType.video ? Icons.videocam : Icons.photo, color: Colors.grey),
          onTap: () {
            if (_selectionMode) {
              setState(() {
                if (isSelected) _selected.remove(file.id); else _selected.add(file.id);
              });
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FileDetailScreen(file: file)));
            }
          },
          onLongPress: () {
            if (!_selectionMode) {
              setState(() {
                _selectionMode = true;
                _selected.add(file.id);
              });
            }
          },
        );
      },
    );
  }

  Widget _buildThumb(TrackedFile file) {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(file.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return AssetEntityImage(snapshot.data!, width: 50, height: 50, fit: BoxFit.cover, isOriginal: false);
        }
        return Container(
          width: 50,
          height: 50,
          color: Colors.grey[300],
          child: Icon(file.type == FileType.video ? Icons.videocam : Icons.photo, color: Colors.grey[600]),
        );
      },
    );
  }

  Widget _buildBottom() {
    final count = _selected.length;
    final size = widget.files.where((f) => _selected.contains(f.id)).fold<int>(0, (sum, file) => sum + file.sizeBytes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count selected', style: Theme.of(context).textTheme.titleMedium),
                Text(_formatSize(size), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Files'),
        content: Text('Delete ${_selected.length} file(s)? Cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFiles();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFiles() async {
    final service = context.read<FileScannerService>();
    final toDelete = widget.files.where((f) => _selected.contains(f.id)).toList();

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    final count = await service.deleteMultipleFiles(toDelete);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $count file(s)'), backgroundColor: Colors.green));
      setState(() {
        _selected.clear();
        _selectionMode = false;
      });
      if (count == widget.files.length) Navigator.pop(context);
    }
  }
}
