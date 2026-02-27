---
description: Git workflow for feature branches, commits, PRs, code review, and squash merge
---

# Feature Branch Workflow

## 1. Create Feature Branch

```bash
# From the main worktree, create and switch to a feature branch
git checkout -b feat/<feature-name>
```

If working on multiple features simultaneously, use **git worktree**:

```bash
# Add a worktree for a parallel feature
git worktree add ../folder-sync-app-<feature-name> -b feat/<feature-name>
```

## 2. Implement with Checkpoint Commits

// turbo-all

Make commits at logical checkpoints during implementation:

```bash
git add -A
git commit --no-gpg-sign -m "<type>: <short description>

<optional body with details>"
```

Commit types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`

## 3. Push Branch and Create PR

```bash
git push origin feat/<feature-name>
```

Then create a PR on GitHub via the browser or CLI:

```bash
# Using GitHub CLI (if installed)
gh pr create --title "feat: <description>" --body "<details>" --base main
```

## 4. Code Review (Software Architect Role)

Review the PR as a **Software Architect** responsible for:

- **Code quality**: clean, readable, no dead code
- **Architecture compliance**: feature-first + clean architecture layers respected
- **Naming conventions**: consistent with project patterns
- **Separation of concerns**: domain ≠ data ≠ presentation
- **Error handling**: proper use of Failure/Exception hierarchy
- **Provider patterns**: correct Riverpod usage (read vs watch, disposal)
- **Performance**: no unnecessary rebuilds, efficient streams
- **Documentation**: public APIs documented, TODOs tracked

## 5. Approve and Squash Merge

Once review passes:

```bash
# Using GitHub CLI
gh pr merge --squash --delete-branch
```

Or via the GitHub UI: select **"Squash and merge"** → delete branch.

## 6. Update Local Main

```bash
git checkout main
git pull origin main
```

If using worktrees, clean up:

```bash
git worktree remove ../folder-sync-app-<feature-name>
```
