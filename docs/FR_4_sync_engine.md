# Draft Implementation Guide: Core Sync Engine

This document outlines the detailed plan for implementing the **Core Sync Engine**, which is the brain of FolderSync. It handles the actual synchronization of files between a local Android folder and a remote Google Drive folder.

## 1. Objective and Requirements

**Objective:** Implement a reliable, background-compatible engine that can synchronize a `SyncTask`'s local and remote folders, handling additions, modifications, deletions, and conflicts.

**Key Requirements:**
1.  **File Traversing:** Ability to scan both the local Android directory and the remote Google Drive folder to build a snapshot of the current state.
2.  **State Tracking:** Maintain a local "Sync State" (e.g., in Hive) for each task to track which files were present during the *last* successful sync. This is crucial for detecting deletions (e.g., "File A existed last time, but is missing locally now — it must have been deleted").
3.  **One-Way vs. Two-Way Sync:**
    *   **Two-Way (Default/Complex):** Changes propagate in both directions. Deleting locally deletes remotely, and vice-versa.
    *   **One-Way (Local to Remote):** The local folder is the absolute source of truth. The remote folder is made to mirror the local folder (like a backup).
4.  **Conflict Resolution (Two-Way):** Implement the Last-Write-Wins (LWW) strategy. If a file was modified on *both* sides since the last sync, compare `modifiedTime` (Drive) and `lastModified()` (Local). The newest file overwrites the older one.
5.  **History Logging:** Record every significant action (upload, download, delete, conflict resolved) as a `SyncHistoryEntry` so it appears on the History screen.
6.  **Progress Tracking:** Update the `SyncTask`'s progress bar (e.g., "Uploading 2/5 files").

## 2. Architecture & Components

The Sync Engine will live primarily in the `sync_tasks` domain and data layers.

### 2.1 Services & Repositories

*   **`LocalFileService` (New)** (in `core/services`): Handles local file system operations using `dart:io`.
    *   `Future<List<LocalFile>> listFiles(String directoryPath)`
    *   `Future<void> copyToLocal(...)`
    *   `Future<void> deleteLocal(...)`
*   **`DriveService` (Update)**: Add methods for downloading, uploading, and deleting specific files.
    *   `Future<void> downloadFile(String fileId, String savePath)`
    *   `Future<DriveItem> uploadFile(String parentFolderId, File localFile, {String? existingFileId})`
    *   `Future<void> deleteFile(String fileId)`
*   **`SyncEngineService` (New)** (in `sync_tasks/domain/services`): The orchestrator class. It coordinates the `LocalFileService`, `DriveService`, `SyncTaskRepository`, and `SyncHistoryRepository`.

### 2.2 The Sync Algorithm (Step-by-Step)

When `syncEngine.runTask(SyncTask task)` is called:

1.  **Initialisation:** Mark task status as `syncing`. Clear previous errors.
2.  **Snapshot Generation:**
    *   **Recursively** scan the remote Google Drive folder and all its subfolders for files. We will need to map flat relative paths (e.g., `Documents/Budget.xlsx`) to remote IDs.
    *   **Recursively** scan the local Android folder and all its subfolders for files.
3.  **State Comparison (The Delta):**
    *   Load the `LastSyncState` (the snapshot of what the folders looked like after the *last* sync).
    *   Compare the current local files, current remote files, and the `LastSyncState`.
    *   Determine the required actions:
        *   **Action: Upload** (File exists locally, not remotely, and not in LastSyncState).
        *   **Action: Download** (File exists remotely, not locally, and not in LastSyncState).
        *   **Action: Delete Remote** (File existed in LastSyncState, exists remotely, but missing locally).
        *   **Action: Delete Local** (File existed in LastSyncState, exists locally, but missing remotely).
        *   **Action: Update Remote** (File modified locally since LastSyncState).
        *   **Action: Update Local** (File modified remotely since LastSyncState).
        *   **Action: Resolve Conflict** (File modified on BOTH sides since LastSyncState).
4.  **Execution:** Iterate through the required actions.
    *   Update `SyncTask` progress (e.g., processed / total).
    *   Perform the actual upload/download/delete.
    *   *If an operation fails, log an error for that specific file but continue.*
5.  **History & Completion:**
    *   Create `SyncHistoryEntry` records for all actions taken.
    *   Save the new compiled `LastSyncState` to Hive.
    *   Mark `SyncTask` status as `upToDate` (or `error` if there were critical failures) and update `lastSyncedAt`.

### 2.3 Data Structures (Models)

We need a way to track the state.

```dart
// To store the state of the last successful sync
class SyncStateSnapshot {
  final String taskId;
  final DateTime syncTimestamp;
  final Map<String, FileSnapshot> files; // Key: relative path
}

class FileSnapshot {
  final String relativePath;
  final String remoteId; // Helpful for updates
  final DateTime localModifiedTime;
  final DateTime remoteModifiedTime;
}
```

## 3. Scope Boundaries for v1

Based on the agreed requirements, the following boundaries are established for the first iteration:

*   **Recursive Nested Folders:** The sync engine **will** recursively traverse nested folders on both the local and remote sides. The `LastSyncState` mapping will need to handle relative paths to accurately track files deeply nested within the synced root folders.
*   **Manual Trigger First (Phased Implementation):** We will build the core engine and orchestrate it via a "Sync Now" button on the Dashboard. This separates the complexity of the core sync logic from Android's background execution limits. Integrating `WorkManager` for scheduled background syncs will be the next logical feature.
*   **Automatic Silent LWW Resolution:** Conflict resolution (modified on both sides since last sync) will automatically pick the file with the most recent modified timestamp (Last-Write-Wins). The "losing" version is silently overwritten locally, but preserved remotely via Google Drive's native 30-day version history.
