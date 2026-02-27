import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/app_providers.dart';
import '../../domain/entities/drive_folder.dart';

/// Screen that allows the user to browse their Google Drive and select a folder.
class DriveFolderPickerScreen extends ConsumerStatefulWidget {
  const DriveFolderPickerScreen({super.key});

  @override
  ConsumerState<DriveFolderPickerScreen> createState() =>
      _DriveFolderPickerScreenState();
}

class _DriveFolderPickerScreenState
    extends ConsumerState<DriveFolderPickerScreen> {
  // Stack of parent folders to handle hierarchical navigation.
  // The last item is the current folder. If empty, we are at root.
  final List<DriveFolder> _pathStack = [];

  String? get _currentParentId =>
      _pathStack.isEmpty ? null : _pathStack.last.id;
  String get _currentPathName =>
      _pathStack.isEmpty ? 'My Drive' : _pathStack.last.name;

  void _navigateToFolder(DriveFolder folder) {
    setState(() {
      _pathStack.add(folder);
    });
  }

  void _navigateUp() {
    if (_pathStack.isNotEmpty) {
      setState(() {
        _pathStack.removeLast();
      });
    } else {
      // Cancelled
      Navigator.of(context).pop();
    }
  }

  void _selectCurrentFolder() {
    // Return the currently viewed folder.
    // If we are at root level and the user clicks select, we return a virtual root node.
    final selectedFolder = _pathStack.isEmpty
        ? const DriveFolder(
            id: 'root',
            name: 'My Drive',
            mimeType: 'application/vnd.google-apps.folder',
          )
        : _pathStack.last;
    Navigator.of(context).pop(selectedFolder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foldersAsyncValue = ref.watch(
      driveFolderListProvider(_currentParentId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _navigateUp),
        title: Text(_currentPathName),
        actions: [
          TextButton(
            onPressed: _selectCurrentFolder,
            child: Text(
              'Select',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: foldersAsyncValue.when(
        data: (folders) {
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This folder is empty.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: Icon(Icons.folder, color: theme.colorScheme.primary),
                title: Text(folder.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _navigateToFolder(folder),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load folders',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(driveFolderListProvider(_currentParentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
