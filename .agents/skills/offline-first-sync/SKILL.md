---
name: offline-first-sync
description: Implement robust offline-first architecture, local caching, and background synchronization for field sales applications.
---

# Offline-First & Sync Skill

Use this skill whenever you are designing or implementing features that must work when the EXFINOPS app loses internet connectivity or needs to sync data with the backend.

## Guidelines

1. **Local State First**: Read from and write to the local database first to ensure the UI remains instantly responsive.
2. **Queueing Operations**: When offline, all mutating operations (e.g., inserting visit records or forms) must be queued locally with a unique temporary ID and a pending status.
3. **Synchronization Logic**: Implement background or manual sync routines that push pending local changes to the PostgreSQL backend, handling timeouts gracefully with retries.
4. **Conflict Resolution**: Define clear rules for conflicts (e.g., "Server Wins" or "Latest Timestamp Wins") when syncing data that might have changed on both ends.
5. **UI Feedback**: Provide clear indicators in the UI to show the user whether they are "Offline", "Syncing", or "Fully Synced".
