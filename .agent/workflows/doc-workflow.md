---
description: Documentation and planning workflow for new features (Requirements Gathering)
---

# Feature Documentation Workflow

Before writing code for a new feature, follow this planning and documentation process to ensure requirements are clear and tracked.

## 1. Requirements Gathering

When starting a new feature, review the relevant Functional Requirements (FR) and Non-Functional Requirements (NFR).

## 2. Draft Implementation Guide

First, create a draft of the implementation guide as an **Artifact** (e.g., in the agent's brain directory like `implementation_plan.md` or a temporary markdown file).

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

## 5. Finalize Implementation Guide

After the review is approved, go ahead and create the final markdown file under the `docs/` folder in the workspace.

- **Naming Convention**: Use the format `FR_<number>_feature_name.md`.
  - Example: `docs/FR_3_google_drive_folder_picker.md`
  - Multiple requirements: `docs/FR_1_NFR_2_dashboard.md`

Once this final file is created and committed, proceed to the execution phase (creating the feature branch in `git-workflow.md`).
