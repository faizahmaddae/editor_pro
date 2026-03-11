# Project Instructions

You are working on a Flutter project.

## Mandatory workflow
Before making any code change, ALWAYS follow these steps in order:

1. Identify which package/library is related to the issue.
2. Read the official package documentation first.
3. If needed, inspect the package source code or examples.
4. Then inspect my project files related to that package.
5. Compare my implementation with the package's intended usage.
6. Explain the root cause briefly before making changes.
7. Then apply the fix.
8. After the fix, run relevant checks/tests if available.

## Important rules
- Never make blind changes.
- Never assume package behavior without checking docs/examples first.
- Prefer official docs, package examples, and source code over guesswork.
- When the bug is related to UI/editor/object position/save-restore logic, trace the full lifecycle end-to-end before editing.
- If package docs are missing or unclear, explicitly say so and inspect source code before proceeding.
- For Flutter packages, check:
  - initialization flow
  - widget lifecycle
  - controller usage
  - state restoration
  - serialization/deserialization
  - scaling/transforms/coordinates
  - rebuild/layout side effects

## For this project
When a task is about `pro_image_editor`, first study:
- pub.dev package docs
- GitHub repository
- examples
- relevant source files

Then inspect:
- editor integration
- save/load project flow
- layer/object restore logic
- object positioning after reload
- Scaffold/layout/rebuild behavior
- custom wrappers and state management

## Output format before coding
Always start with:
1. Related package
2. What I checked
3. Suspected root cause
4. Fix plan

Only then begin changing code.