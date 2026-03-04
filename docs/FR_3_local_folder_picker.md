# FR-3: Local Folder Picker

## Objective
Implement a native Android folder picker to allow users to select a local destination directory for their sync task. This completes the "local Android folder picker" requirement specified in FR-3.

## Requirements Covered
- **FR-3**: Add New Sync Task — form with: local Android folder picker.
- **NFR-1**: Android first (Using Storage Access Framework for native Android experience).
- **NFR-5**: Responsive & performant.

## Architecture & Components

### Domain Layer
No new entities are required. The local folder is represented purely by its absolute string path inside the `SyncTask` entity.

### Data Layer
- **Permissions**: The Storage Access Framework (SAF) will be used to pick a directory. On modern Android versions (API 29+), SAF does not require explicit `READ_EXTERNAL_STORAGE` or `WRITE_EXTERNAL_STORAGE` permissions for the user to select a directory. We will rely on SAF for access.
- Any file I/O operations later will use this selected URI/path.

### Presentation Layer
#### [MODIFY] `add_task_screen.dart`
- Update the `_FolderPicker` widget for the "Local Android Folder" section.
- Instead of using a static string `/sdcard/Documents/Sync`, tapping the picker will launch the native folder picker.
- **Capabilities**: The native Android picker (Storage Access Framework) natively supports full file system navigation and creating new folders on the fly without any extra code on our end.
- The returned local directory path will update the `_localFolderPath` state variable and be displayed on the screen.

## State Management
- Local Component State: Simple `setState` inside `AddTaskScreen` will be used to hold `_localFolderPath` since it is purely transient form state before saving the sync task. No Riverpod provider is needed until the task is actually saved.

## Dependencies
#### [MODIFY] `pubspec.yaml`
- Add the `file_picker` plugin to handle native directory selection via `FilePicker.platform.getDirectoryPath()`.

## Testing Strategy

### Automated Tests
Run standard analysis to ensure no regressions:
```bash
flutter analyze
```

### Manual Verification
1. Open the "Add New Sync Task" form on the connected Android device.
2. Tap the "Select Local Folder" button.
3. Verify the native Android file picker opens (Storage Access Framework).
4. Navigate and select a local directory.
5. Verify the selected directory's absolute path appears correctly in the `AddTaskScreen` form.
6. Verify that cancelling the picker does not crash the app and leaves the previous value (or null) intact.
