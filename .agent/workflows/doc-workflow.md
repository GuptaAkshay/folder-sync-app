---
description: Documentation and planning workflow for new features (Requirements Gathering)
---

# Feature Documentation Workflow

Before writing code for a new feature, follow this planning and documentation process to ensure requirements are clear and tracked.

## 1. Requirements Gathering

When starting a new feature, review the relevant Functional Requirements (FR) and Non-Functional Requirements (NFR).

## 2. Create Implementation Guide

Create a specific implementation guide under the `docs/` directory.

- **Naming Convention**: Name the file after the FR/NFR numbers it addresses.
  - Single requirement: `docs/FR-1.md`
  - Multiple requirements: `docs/FR-1_NFR-2.md`

## 3. Guide Structure

The implementation guide should include:

- **Objective**: What is being built and why.
- **Requirements Covered**: List of FRs and NFRs explicitly addressed by this document.
- **Architecture & Components**: Impacted layers (Domain, Data, Presentation) and new files to be created.
- **State Management**: New Riverpod providers or state changes needed.
- **Dependencies**: Any new packages or external APIs required.
- **Testing Strategy**: How the feature will be verified (UI tests, unit tests, manual device testing).

## 4. Review and Proceed

Once the implementation guide is written, review it with the user or as a Software Architect before moving to the execution phase (creating the feature branch).
