---
name: location-and-gps-tracking
description: Manage location services, permissions, background tracking, and battery optimization for route planning and field operations.
---

# Location & GPS Tracking Skill

Use this skill whenever working on GPS, geolocation, maps, or route planning aspects of the EXFINOPS field sales app.

## Guidelines

1. **Strict Permission Handling**: Always check and request location permissions explicitly before attempting to get the location. Gracefully handle the scenario where the user denies the permission by explaining why it's needed via UI.
2. **Battery Optimization**: Use the lowest acceptable accuracy for the task. Do not continuously poll high-accuracy GPS if network/cell-tower accuracy is sufficient, or if the user is stationary.
3. **Background Tracking Safeties**: If background tracking is required, ensure it adheres strictly to iOS and Android background execution limits and verify it doesn't drain the battery.
4. **Mock Locations**: Be aware of mock locations (spoofed GPS). Depending on business rules, detect and handle mock locations properly to prevent field sales fraud.
5. **State Management Integration**: Ensure location updates are streamed optimally to the app state (e.g., Provider/GetX models) to prevent unnecessary widget rebuilds.
