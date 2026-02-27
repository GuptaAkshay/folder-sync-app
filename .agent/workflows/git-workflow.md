---
description: Git workflow for feature branches, commits, PRs, code review, and squash merge
---

# Feature Branch Workflow

> Uses the **GitHub MCP server** for PR creation, review, and merge.

## 1. Create Feature Branch

```bash
# From main, create and switch to a feature branch
git checkout -b feat/<feature-name>
```

If working on multiple features simultaneously, use **git worktree**:

```bash
git worktree add ../folder-sync-app-<feature-name> -b feat/<feature-name>
```

## 2. Implement with Checkpoint Commits

// turbo-all

Make commits at logical checkpoints:

```bash
git add -A
git commit --no-gpg-sign -m "<type>: <short description>

<optional body with details>"
```

Commit types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`

## 3. Push Branch

```bash
git push origin feat/<feature-name>
```

## 4. Create PR via GitHub MCP

Use the GitHub MCP server's `create_pull_request` tool:

```
Tool: create_pull_request (MCP server: github)
Arguments:
  owner: GuptaAkshay
  repo: folder-sync-app
  title: "<type>: <description>"
  body: "## Summary\n<what and why>\n\n## Changes\n<file-level details>\n\n## Testing\n<verification steps>"
  head: feat/<feature-name>
  base: main
```

## 5. Validate on Connected Device

Before reviewing and merging, build and deploy the app to a connected device to verify the changes work as expected:

// turbo-all

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.foldersync.folder_sync/.MainActivity
```

Verify the specific feature changes on the physical device or emulator.

## 6. Code Review via GitHub MCP (Software Architect Role)

Use `get_pull_request` and `list_pull_request_files` to review:

```
Tool: get_pull_request (MCP server: github)
Tool: get_pull_request_diff (MCP server: github)
```

Review as a **Software Architect** responsible for:

- **Code quality**: clean, readable, no dead code
- **Architecture compliance**: feature-first + clean architecture layers
- **Naming conventions**: consistent with project patterns
- **Separation of concerns**: domain ≠ data ≠ presentation
- **Error handling**: proper use of Failure/Exception hierarchy
- **Provider patterns**: correct Riverpod usage (read vs watch, disposal)
- **Performance**: no unnecessary rebuilds, efficient streams
- **Documentation**: public APIs documented, TODOs tracked

Add review comments via MCP if needed:

```
Tool: create_pull_request_review (MCP server: github)
Arguments:
  owner: GuptaAkshay
  repo: folder-sync-app
  pull_number: <PR number>
  event: "APPROVE"  # or "REQUEST_CHANGES"
  body: "<review summary>"
```

## 7. Squash Merge via GitHub MCP

Once review passes:

```
Tool: merge_pull_request (MCP server: github)
Arguments:
  owner: GuptaAkshay
  repo: folder-sync-app
  pull_number: <PR number>
  merge_method: "squash"
```

## 8. Update Local Main

// turbo-all

```bash
git checkout main
git pull origin main
```

If using worktrees, clean up:

```bash
git worktree remove ../folder-sync-app-<feature-name>
git branch -D feat/<feature-name>
```
