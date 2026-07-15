---
name: error-handling-and-resilience
description: Define standards for try-catch blocks, error logging, and resilient application behavior.
---

# Error Handling & Resilience Skill

Use this skill whenever writing network requests, database operations, or complex business logic.

## Guidelines

1. **No Swallowed Exceptions**: Never write an empty `catch` block (`catch (e) {}`). At minimum, log the error and its stack trace.
2. **User-Friendly Feedback**: Differentiate between technical logs (sent to `errors.log` or Crashlytics) and user messages. Map cryptic exceptions to actionable localized strings before displaying them in UI (e.g., SnackBar).
3. **Graceful Degradation**: If an external service or a specific module fails, the rest of the application should remain usable if possible. Use fallback mechanisms (e.g., cached data when fetching fails).
4. **Specific Catching**: Catch specific exceptions (e.g., `PostgreSQLConnectionException`, `SocketException`) before a generic `catch (e)`.
