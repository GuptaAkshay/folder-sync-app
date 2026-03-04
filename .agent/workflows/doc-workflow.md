---
description: Documentation and planning workflow for new features (Requirements Gathering)
---

# Feature Documentation Workflow

Before writing code for a new feature, follow this planning and documentation process to ensure requirements are clear and tracked.

## 1. Requirements Gathering

When starting a new feature, review the relevant Functional Requirements (FR) and Non-Functional Requirements (NFR).

## 2. Create a Documentation Branch

Create a new branch specifically for the documentation named `<feature_name>_doc` (e.g., `sync_engine_doc`).

```bash
git checkout main
git pull
mkdir -p wt
git worktree add wt/<feature_name>_doc -b <feature_name>_doc
cd wt/<feature_name>_doc
```

## 3. Draft Implementation Guide

Create the draft of the implementation guide directly in the `docs/` folder on this new branch (e.g., `docs/FR_<number>_<feature_name>.md`).

## 3. Guide Structure

The draft implementation guide should include:

- **Objective**: What is being built and why.
- **Requirements Covered**: List of FRs and NFRs explicitly addressed by this document.
- **Architecture & Components**: Impacted layers (Domain, Data, Presentation) and new files to be created.
- **State Management**: New Riverpod providers or state changes needed.
- **Dependencies**: Any new packages or external APIs required.
- **Testing Strategy**: How the feature will be verified (UI tests, unit tests, manual device testing).

## 4. Artifact Review Process

Once the draft is written, use the **`notify_user`** tool to ask for an **Artifact Review**. Set `BlockedOnUser: true` to halt execution until the user (or Software Architect) approves the proposed architecture and plan.

## 5. Commit and Move to Feature Implementation

After the review is approved, commit the newly created document to the `<feature_name>_doc` branch:

```bash
git add docs/FR_<number>_<feature_name>.md
git commit --no-gpg-sign -m "docs: add implementation guide for <feature_name>"
```

Follow the PR process in `git-workflow.md` to merge this documentation branch into `main`. Once merged, you can proceed to create the actual feature implementation branch (e.g., `feat/<feature_name>`).
