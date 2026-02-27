import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/utils/app_logger.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the logging system
  AppLogger.init();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open Hive boxes
  final syncTaskBox = await Hive.openBox<String>('sync_tasks');
  final syncHistoryBox = await Hive.openBox<String>('sync_history');

  runApp(
    ProviderScope(
      overrides: [
        syncTaskBoxProvider.overrideWithValue(syncTaskBox),
        syncHistoryBoxProvider.overrideWithValue(syncHistoryBox),
      ],
      child: const FolderSyncApp(),
    ),
  );
}
