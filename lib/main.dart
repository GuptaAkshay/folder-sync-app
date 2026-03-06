import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/app.dart';
import 'core/utils/app_logger.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request storage permissions at app startup
  final manageStatus = await Permission.manageExternalStorage.request();
  final storageStatus = await Permission.storage.request();

  AppLogger.init();
  AppLogger.i(
    '[MAIN] MANAGE_EXTERNAL_STORAGE: ${manageStatus.name} | READ_EXTERNAL_STORAGE: ${storageStatus.name}',
  );
  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open Hive boxes
  final syncTaskBox = await Hive.openBox<String>('sync_tasks');
  final syncHistoryBox = await Hive.openBox<String>('sync_history');
  final syncStateBox = await Hive.openBox<String>('sync_states');

  runApp(
    ProviderScope(
      overrides: [
        syncTaskBoxProvider.overrideWithValue(syncTaskBox),
        syncHistoryBoxProvider.overrideWithValue(syncHistoryBox),
        syncStateBoxProvider.overrideWithValue(syncStateBox),
      ],
      child: const FolderSyncApp(),
    ),
  );
}
