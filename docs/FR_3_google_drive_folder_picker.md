# Implementation Guide: Google Drive Folder Picker

## Objective
Implement a Google Drive folder picker to allow users to select a remote cloud folder when creating a new sync task. This is the first component needed for the "Add New Sync Task" form.

## Requirements Covered
- **FR-3**: Add New Sync Task — remote folder picker (Google Drive API).
- **FR-0c**: Mid-session Re-auth — handle 401 errors during folder picking gracefully (triggers silent refresh or re-auth).
- **NFR-2**: Client-side only — Google Drive access via client-side OAuth + Drive API.

## Architecture & Components

### Domain Layer
- **Entity**: `DriveFolder` (id, name, mimeType).
- **Repository Interface**: Expand `SyncTaskRepository` (or create a new `DriveRepository` interface) to include `Future<List<DriveFolder>> getFolders({String? parentId})`.
  *Note: Given the specific nature of Drive API operations, a dedicated `DriveRepository` in the `sync_tasks` feature (or a shared `drive` feature) is appropriate.*

### Data Layer
- **Implementation**: Expand `DriveService` (created during Quota implementation) to include:
  - `Future<List<DriveFolder>> listFolders(String accessToken, {String? folderId})`
  - Uses `DriveApi.files.list` with query `mimeType='application/vnd.google-apps.folder' and trashed=false`. If `folderId` is provided, add `'folderId' in parents`.

### Presentation Layer
- **Screen/Dialog**: `DriveFolderPickerScreen` (or a bottom sheet/dialog).
- **UI Elements**:
  - App bar with current path / "Back" button.
  - `ListView` of `ListTile`s showing folder icons and names.
  - "Select this folder" floating action button or checkmark.
  - Loading indicators (`CircularProgressIndicator`) while fetching folders.
  - Error states (empty state, network error state).

## State Management
- **Provider**: `driveFolderListProvider(String? parentId)`
  - A `FutureProvider.family` or `AsyncNotifierFamily` that watches the `authStateProvider`.
  - Fetch folders for the given `parentId` (null = root).
- **Error Handling**: Catch `DetailedApiRequestError` (from googleapis). If statusCode is 401, trigger the auth state re-evaluation (handled via `authStateProvider` or an explicit refresh call).

## Dependencies
- `googleapis` (already installed)
- `googleapis_auth` (already installed)
- `flutter_riverpod` (already installed)

## Testing Strategy
- **Manual Device Testing**:
  - Connect a real Google account.
  - Open the picker and verify the root Drive folders load.
  - Navigate into a subfolder and verify its contents load.
  - Navigate back up the hierarchy.
  - Select a folder and verify the correct ID and name are returned to the caller.
  - Revoke Drive access via Google Account settings, try to open the picker, and verify the app handles the 401 (triggers re-auth prompt).
