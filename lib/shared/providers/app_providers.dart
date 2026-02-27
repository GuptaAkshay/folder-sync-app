import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../features/sync_tasks/data/repositories/sync_task_repository_impl.dart';
import '../../../features/sync_tasks/domain/entities/sync_task.dart';
import '../../../features/sync_tasks/domain/repositories/sync_task_repository.dart';
import '../../../features/history/data/repositories/sync_history_repository_impl.dart';
import '../../../features/history/domain/entities/sync_history_entry.dart';
import '../../../features/history/domain/repositories/sync_history_repository.dart';

// ─── Auth Providers ─────────────────────────────────

/// Provides the auth repository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Notifier that manages auth state throughout the app.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repo = ref.read(authRepositoryProvider);

    // Attempt silent refresh on app start
    final refreshed = await repo.silentRefresh();
    if (refreshed) {
      return repo.getCurrentUser();
    }
    return null;
  }

  Future<AuthUser> signIn() async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    try {
      final user = await repo.signIn();
      state = AsyncData(user);
      return user;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncData(null);
  }

  /// Attempt silent refresh (FR-0c mid-session re-auth).
  Future<bool> silentRefresh() async {
    final repo = ref.read(authRepositoryProvider);
    final success = await repo.silentRefresh();
    if (success) {
      final user = await repo.getCurrentUser();
      state = AsyncData(user);
    }
    return success;
  }
}

// ─── Sync Task Providers ────────────────────────────

/// Hive box for sync tasks.
final syncTaskBoxProvider = Provider<Box<String>>((ref) {
  throw UnimplementedError('syncTaskBoxProvider must be overridden');
});

/// Provides the sync task repository instance.
final syncTaskRepositoryProvider = Provider<SyncTaskRepository>((ref) {
  final box = ref.read(syncTaskBoxProvider);
  return SyncTaskRepositoryImpl(box: box);
});

/// Stream of all sync tasks for real-time dashboard updates.
final syncTasksStreamProvider = StreamProvider<List<SyncTask>>((ref) {
  final repo = ref.read(syncTaskRepositoryProvider);
  return repo.watchAllTasks();
});

/// Convenience provider for a simple async list of tasks.
final syncTasksProvider = FutureProvider<List<SyncTask>>((ref) async {
  final repo = ref.read(syncTaskRepositoryProvider);
  return repo.getAllTasks();
});

// ─── History Providers ──────────────────────────────

/// Hive box for sync history.
final syncHistoryBoxProvider = Provider<Box<String>>((ref) {
  throw UnimplementedError('syncHistoryBoxProvider must be overridden');
});

/// Provides the sync history repository instance.
final syncHistoryRepositoryProvider = Provider<SyncHistoryRepository>((ref) {
  final box = ref.read(syncHistoryBoxProvider);
  return SyncHistoryRepositoryImpl(box: box);
});

/// Stream of all history entries for real-time updates.
final syncHistoryStreamProvider = StreamProvider<List<SyncHistoryEntry>>((ref) {
  final repo = ref.read(syncHistoryRepositoryProvider);
  return repo.watchAllEntries();
});
