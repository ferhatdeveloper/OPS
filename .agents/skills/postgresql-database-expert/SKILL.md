---
name: postgresql-database-expert
description: Ensure secure, optimized, and robust direct PostgreSQL interactions from Dart/Flutter.
---

# PostgreSQL Database Expert Skill

Use this skill whenever you are writing, refactoring, or reviewing direct PostgreSQL database interactions in the EXFINOPS Flutter app.

## Guidelines

1. **Security (SQL Injection Prevention)**: ALWAYS use parameterized queries or prepared statements (e.g., using `@parameter` syntax or substitution variables). NEVER concatenate user inputs directly into raw SQL strings.
2. **Connection Management**: Ensure connections are properly managed. Do not open a new connection for every small query if a pool or maintained connection is appropriate, but gracefully handle disconnections and timeouts.
3. **Transaction Management**: Ensure operations that modify multiple tables or rely on atomic execution are strictly wrapped in database transactions (`BEGIN`, `COMMIT`, `ROLLBACK`).
4. **Error Handling & Resilience**: Catch PostgreSQL specific exceptions. Do not expose raw database errors directly to the UI; instead, map them to user-friendly messages and log the detailed technical errors.
5. **Data Mapping**: Ensure robust serialization/deserialization between database rows and Dart models. Handle `null` values meticulously in SQL results to prevent Dart null safety crashes.
