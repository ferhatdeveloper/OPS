---
name: clean-architecture-enforcer
description: Enforce Clean Architecture principles (Presentation, Domain, Data) and prevent business logic leaks into UI components.
---

# Clean Architecture Enforcer Skill

Use this skill whenever creating new features, refactoring existing ones, or reviewing code in the EXFINOPS app.

## Guidelines

1. **Separation of Concerns**: Strictly enforce the boundary between the UI (`lib/view` or `lib/modules/.../view`), Business Logic (`.../viewmodel` or `.../controllers`), and Data layers (`lib/core/services`, `.../repository`).
2. **No Data Logic in UI**: UI widgets MUST NOT contain raw database queries, HTTP requests, or complex state manipulations. They should only listen to state from ViewModels/Providers and trigger intent actions.
3. **Data Mapping**: Ensure that JSON or database responses are mapped to immutable Domain Models before reaching the UI or Business Logic layer. Use `freezed` or `json_serializable` systematically.
4. **Dependency Injection**: Services and repositories should not be instantiated directly within ViewModels; they should be passed in via constructor injection or a locator pattern.
