---
name: state-management-master
description: Establish standard patterns for using Provider/Riverpod/GetX, preventing memory leaks and UI render issues.
---

# State Management Master Skill

Use this skill whenever working with Flutter state management (Provider, Riverpod, or GetX) in EXFINOPS.

## Guidelines

1. **Granular Rebuilds**: Ensure only the necessary widgets rebuild when state changes. Avoid calling `notifyListeners()` (or equivalent) excessively. Use Selector or Consumer widgets locally rather than putting them at the top of large widget trees.
2. **Context Safety**: Do not use `BuildContext` across async gaps safely. Always check `if (!context.mounted) return;` before navigating or showing dialogs after an `await`.
3. **Business Logic Isolation**: Providers/ViewModels must hold all business logic. They should expose data cleanly (e.g., via state enums like `LoadingState.loading`, `.success`, `.error`) rather than UI elements.
4. **Resource Cleanup**: Always override the `dispose()` method in Providers/Controllers to cancel streams, timers, and controllers to prevent memory leaks.
