---
name: production-checklist
description: Verify application readiness before building binaries for iOS/Android distribution.
---

# Production Readiness Checklist Skill

Use this skill whenever you are preparing the EXFINOPS app for a production build, App Store release, or Google Play release.

## Guidelines

1. **Environment Variables & Secrets**: Ensure all debug/development endpoints, passwords, and API keys are completely stripped and replaced with production equivalents. 
2. **Build Configurations**: Verify that debug modes (e.g., logging network requests, debug banner, verbose print statements) are conditionally disabled in the release build.
3. **Permissions (Info.plist & AndroidManifest)**: Guarantee that all required privacy usage descriptions (e.g., `NSLocationWhenInUseUsageDescription`) are present and accurate. Failure to do so will result in App Store rejection.
4. **Code Signing & Provisioning**: Confirm that the correct Production/Distribution certificates and provisioning profiles are configured in Xcode before initiating an iOS build.
5. **Semantic Versioning**: Verify that the `pubspec.yaml` version and build number have been properly incremented prior to build.
