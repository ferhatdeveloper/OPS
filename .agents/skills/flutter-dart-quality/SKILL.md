---
name: flutter-dart-quality
description: Enforce high-quality Flutter and Dart development practices, including state management, responsive UI, and clean architecture.
---

# Flutter & Dart Quality Skill

Use this skill whenever you are writing, refactoring, or reviewing Flutter code (Dart).

## Guidelines

1. **State Management**: Identify the project's primary state management (e.g., GetX, Provider, Riverpod, BLoC) and strictly adhere to its patterns. Do not mix state management solutions unless explicitly required.
2. **Clean Architecture**: Keep UI (`lib/view`), Business Logic (`lib/controllers` or `lib/viewmodels`), and Data Layers (`lib/services` or `lib/repositories`) separated.
3. **Effective Dart**: Follow official Effective Dart guidelines:
   - Use `const` constructors where possible for performance.
   - Use `final` for variables that do not change after initialization.
   - Prefer early returns and avoid deep nesting.
4. **Error Handling**: Always implement proper error handling in services and repositories, and use user-friendly UI mechanisms (like SnackBars or dialogs) to communicate failures.
5. **UI & Responsiveness**: 
   - Avoid hardcoding sizes. Use `MediaQuery` or responsive builders.
   - Separate large widgets into smaller, private widgets or separate files to improve readability.
6. **Imports**: Prefer relative imports for files within the same folder or feature block, and package imports for files outside. Avoid unused imports.

## Verification
- Run `flutter analyze` to ensure code quality rules are fulfilled.
- Verify `const` widget usage to prevent unnecessary rebuilds.
