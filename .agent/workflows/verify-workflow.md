---
description: Verification workflow after feature implementation
---

# Verification Workflow

This workflow should be executed after every feature implementation is complete to verify that the app builds correctly, runs on the device, and to analyze runtime logs for any potential issues or crashes.

## Step 1: Build and Install the App

Run the app on the connected device with the recent build containing the latest changes.

// turbo
```bash
cd /root/workspace/folder-sync-app
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.foldersync.folder_sync/.MainActivity
```

## Step 2: Continuous Log Monitoring

In a new background terminal command, start capturing `adb logcat` output filtered specifically for the app ID (`com.foldersync.folder_sync`). Let this command run continuously in the background to monitor the app in real-time.

We will redirect these logs to a newly created file under `logs` directory with a timestamp and the feature name to ensure no previous log files are overridden. 

```bash
# Agent MUST replace <TIMESTAMP> and <FEATURE_NAME> before running. Example: 20260227_drive_folder_picker.txt
# Leave this command running in the background. DO NOT terminate it.
mkdir -p /root/workspace/folder-sync-app/logs
adb logcat --pid=$(adb shell pidof -s com.foldersync.folder_sync) > /root/workspace/folder-sync-app/logs/<TIMESTAMP>_<FEATURE_NAME>.txt
```

*Note to agent: Keep this background command running indefinitely. Monitor the status using `command_status` periodically if needed, but do not kill the command.*

## Step 3: Analyze the Logs (On Demand)

Do not analyze the logs immediately. Wait until the user explicitly asks you to "analyze the logs", or if the user states the app was killed or crashed.

1. Once requested by the user, you may terminate the background logcat command or simply read the resulting log file.
2. Read the contents of the newly created log file using `view_file` or `grep_search`.
3. Analyze the logs for any `E/` (Error) or `F/` (Fatal) tags, stack traces, unhandled exceptions, or potential issues.
4. Report back to the user with a summary of the analysis. If everything is clear, state that the verification passed successfully.