import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/file_scanner_service.dart';
import '../models/tracked_file.dart';
import 'file_list_screen.dart';
import '../widgets/storage_card.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileScannerService>().loadFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Memory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Consumer<FileScannerService>(
        builder: (context, service, child) {
          if (service.isScanning) return _buildScanning(service);
          if (service.errorMessage != null) return _buildError(service);
          if (service.allFiles.isEmpty) return _buildEmpty();
          return _buildContent(context, service);
        },
      ),
      floatingActionButton: Consumer<FileScannerService>(
        builder: (context, service, child) {
          return FloatingActionButton.extended(
            onPressed: service.isScanning ? null : () => service.scanFiles(),
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Files'),
          );
        },
      ),
    );
  }

  Widget _buildScanning(FileScannerService service) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Scanning...', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('${(service.scanProgress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: LinearProgressIndicator(value: service.scanProgress),
          ),
        ],
      ),
    );
  }

  Widget _buildError(FileScannerService service) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(service.errorMessage ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => service.scanFiles(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text('No Files Scanned Yet', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text('Tap the scan button to discover files', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, FileScannerService service) {
    return FutureBuilder<Map<String, dynamic>>(
      future: service.getStorageStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () => service.scanFiles(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StorageCard(totalSize: stats['totalSize'] as int, fileCount: stats['fileCount'] as int),
              const SizedBox(height: 16),
              CategoryCard(
                title: 'Old Files',
                subtitle: '6+ months old',
                fileCount: service.oldFiles.length,
                totalSize: stats['oldFilesSize'] as int,
                icon: Icons.schedule,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileListScreen(title: 'Old Files', files: service.oldFiles)),
                ),
              ),
              const SizedBox(height: 12),
              CategoryCard(
                title: 'Large Files',
                subtitle: '50+ MB each',
                fileCount: service.largeFiles.length,
                totalSize: stats['largeFilesSize'] as int,
                icon: Icons.storage,
                color: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileListScreen(title: 'Large Files', files: service.largeFiles)),
                ),
              ),
              const SizedBox(height: 12),
              CategoryCard(
                title: 'All Photos',
                subtitle: 'View all photos',
                fileCount: service.allFiles.where((f) => f.type == FileType.photo).length,
                totalSize: service.allFiles.where((f) => f.type == FileType.photo).fold<int>(0, (sum, file) => sum + file.sizeBytes),
                icon: Icons.photo,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FileListScreen(
                      title: 'Photos',
                      files: service.allFiles.where((f) => f.type == FileType.photo).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('File Memory v1.0.0'), SizedBox(height: 8), Text('Discover forgotten files')],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
