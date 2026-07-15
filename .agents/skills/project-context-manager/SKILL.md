---
name: project-context-manager
description: Ensures the agent always understands the project structure, avoids hallucinating folder structures, and maintains context by checking the project map.
---

# Project Context Manager Skill

Use this skill whenever starting a new task, returning after a long conversation, or if you feel unsure about the EXFINOPS project structure.

## Guidelines

1. **Never Guess Paths**: Do not hallucinate or guess file paths. If you are unsure where a model, view, or service is located, use `find` or search tools rather than assuming a standard Flutter directory structure.
2. **Review Project Root**: Before making architectural changes, review the `lib/` directory structure to remind yourself of the active feature modules.
3. **Module Boundaries**: Respect the `modules/field_sales` boundary. Do not accidentally mix admin or core files into feature specific folders.
4. **Current Status Check**: If context is lost, read `pubspec.yaml` to understand current dependencies and `lib/main.dart` to understand the initialization flow before writing any code.
