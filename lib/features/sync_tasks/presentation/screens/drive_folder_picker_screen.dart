import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart';

import '../../../../shared/providers/app_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/drive_folder.dart';

class DriveFolderPickerScreen extends ConsumerWidget {
  final String? parentId;
  final String folderName;

  final String folderPath;

  const DriveFolderPickerScreen({
    super.key,
    this.parentId,
    this.folderName = 'Root Directory',
    this.folderPath = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderListAsync = ref.watch(driveFolderListProvider(parentId));

    return Scaffold(
      appBar: AppBar(title: Text(folderName)),
      bottomNavigationBar: parentId == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: () {
                    // Select the CURRENT folder
                    final selectedFolder = DriveFolder(
                      id: parentId!,
                      name: folderName,
                      path: folderPath,
                    );
                    Navigator.of(context).pop(selectedFolder);
                  },
                  icon: const Icon(Icons.check),
                  label: Text('Use "$folderName"'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
      body: folderListAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return const Center(child: Text('This folder is empty.'));
          }
          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final item = folders[index];
              final isFolder =
                  item.mimeType == 'application/vnd.google-apps.folder';

              return ListTile(
                leading: Icon(
                  isFolder ? Icons.folder : Icons.insert_drive_file,
                  color: isFolder ? Colors.blue : Colors.grey,
                ),
                title: Text(item.name),
                onTap: isFolder
                    ? () async {
                        // Navigate into the tapped folder
                        final selected = await Navigator.of(context)
                            .push<DriveFolder>(
                              MaterialPageRoute(
                                builder: (context) => DriveFolderPickerScreen(
                                  parentId: item.id,
                                  folderName: item.name,
                                  folderPath: '$folderPath/${item.name}',
                                ),
                              ),
                            );
                        // If a folder was selected deeper in the stack, pop it back up
                        if (selected != null && context.mounted) {
                          Navigator.of(context).pop(selected);
                        }
                      }
                    : () {
                        // It's a file, show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a folder, not a file.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.e(
            'Error loading folders: $error',
            error: error,
            stackTrace: stack,
          );

          // Handle 401 specifically
          if (error is DetailedApiRequestError && error.status == 401) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Trigger silent refresh or full sign out.
              // We can rely on the existing auth state listeners in the dashboard,
              // but we should probably close this dialog and let the app handle it.
              Navigator.of(context).pop();
              ref.read(authStateProvider.notifier).silentRefresh();
            });
            return const Center(child: Text('Session expired. Refreshing...'));
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}
