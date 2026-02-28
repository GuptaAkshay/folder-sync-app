# Implementation Guide: Google Drive Folder Picker

## Objective
Implement a Google Drive folder picker to allow users to select a remote cloud folder when creating a new sync task. This is the first component needed for the "Add New Sync Task" form. The picker should only display and allow navigating into folders. Files should be explicitly filtered out at the API level.

## Requirements Covered
- **FR-3**: Add New Sync Task — remote folder picker (Google Drive API).
- **FR-0c**: Mid-session Re-auth — handle 401 errors during folder picking gracefully (triggers silent refresh or re-auth).
- **NFR-2**: Client-side only — Google Drive access via client-side OAuth + Drive API.

## Architecture & Components

### Domain Layer
### Domain Layer
- **Entity**: `DriveFolder` (id, name, mimeType). Since we are exclusively dealing with folders, we can retain the `DriveFolder` entity instead of generalizing to `DriveItem`.
- **Repository Interface**: Expand `SyncTaskRepository` (or create a new `DriveRepository` interface) to include `Future<List<DriveItem>> getItems({String? parentId})`.

### Data Layer
- **Implementation**: Expand `DriveService` (created during Quota implementation) to include:
  - `Future<List<DriveFolder>> listFolders(String accessToken, {String? folderId})`
  - Uses `DriveApi.files.list` with specific parameters:
    - `q`: `mimeType='application/vnd.google-apps.folder' and trashed=false`. If `folderId` is provided, append ` and '<folderId>' in parents`.
    - `$fields`: Request a richer set of properties to enhance the UI: `files(id, name, mimeType, iconLink, size, modifiedTime)`.
    - `orderBy`: `folder, name` (to consistently sort folders at the top, followed by files alphabetically).
    - `pageSize`: Explicitly manage limits (e.g., 1000 items) or note pagination needs via `nextPageToken`.
    - `supportsAllDrives`: Set to `true` and `includeItemsFromAllDrives: true` to ensure the picker can browse Shared Drives, not just "My Drive".

### Presentation Layer
- **Screen/Dialog**: `DriveFolderPickerScreen` (or a bottom sheet/dialog).
- **UI Elements**:
  - App bar with current path / "Back" button.
  - "Select this folder" button in the AppBar to select the *currently viewed* folder.
  - `ListView` of `ListTile`s showing only folders.
    - Folders: folder icon, tapping navigates into the folder.
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
  - Open the picker and verify the root Drive folders load (no files should be visible).
  - Navigate into a subfolder and verify its folder contents load.
  - Select a folder via the AppBar button and verify the correct ID and name are returned.
  - Revoke Drive access via Google Account settings, try to open the picker, and verify the app handles the 401 (triggers re-auth prompt).
