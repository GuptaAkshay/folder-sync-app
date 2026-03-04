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
    *   Scan the remote Google Drive folder for all files.
    *   Scan the local Android folder for all files.
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

To ensure we can deliver this without getting bogged down in endless edge cases, we should establish some boundaries for the first iteration:

*   **Flat Folders Only First (Optional but Recommended):** For v1, we could restrict sync to files directly inside the selected folder (no nested sub-folders). *Should we support nested folders right away? It requires recursive Drive API calls and complex local mirroring.*
*   **Manual Trigger First:** Before we integrate `WorkManager` for background jobs, we will implement a "Sync Now" button on the Dashboard card to trigger the engine manually and observe the logs/history.
*   **One-Way Sync First (Optional):** We could build Local → Remote one-way sync first to validate the upload logic, then add Two-Way logic incrementally.

## 4. Required Decisions (Action required from User)

Before I start coding, I need your input on the following:

1.  **Nested Folders:** Should the sync engine recursively traverse nested folders, or just sync the flat files sitting directly inside the selected root folders for now? (Flat is significantly easier for Google Drive API querying).
2.  **Implementation Phases:** Are you okay with implementing the core engine and wiring it to a manual "Sync Now" button first, and leaving the background scheduled `WorkManager` (Hourly/Daily) for the *next* feature after this?
3.  **Conflict Resolution UI:** As per the plan, LWW is automatic and silent. The "losing" version is kept as a previous version in Drive. Are you happy to proceed with this invisible auto-resolution for now?

Please review these details. Once you approve or answer the questions, I will format this into a formal `docs/FR_sync_engine.md` and begin the execution phase.
