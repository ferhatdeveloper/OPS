---
name: automatic-translation
description: Automatically translate new keys in tr.json to all supported languages (EN, AR, KU, FA, etc.)
---

# Automatic Translation Skill

This skill ensures that whenever a new key is added to the Turkish localization file (`assets/translations/tr.json`), it is automatically translated and added to all other supported language files.

## Workflow

1.  **Add Key to Turkish**: Add your new localization key and value to `assets/translations/tr.json`.
2.  **Trigger Translation**: When a new translation is required, DO NOT try to manually add keys to all 10+ languages. Instead, use the automated script designed for this task.
3.  **Run the Script**: 
    - The `translation_sync.dart` script uses the `GoogleTranslator` API (via the `translator` package).
    - It reads `tr.json` as the source of truth, finds any keys missing in other languages (`en`, `ar`, `ku`, `fa`, `de`, `ru`, `es`, `fr`, `zh`, etc.), translates them, and safely appends them without breaking JSON structure or placeholders like `{username}`.
    - Run the script with: `dart run .agents/skills/automatic-translation/scripts/translation_sync.dart`.
4.  **Verify**: Ensure the script completed successfully by checking the terminal output or the Git diff.

## Supported Languages
-   `tr`: Turkish (Source)
-   `en`: English
-   `ar`: Arabic
-   `ku`: Kurdish (Sorani)
-   `fa`: Persian
-   `de`: German
-   `ru`: Russian

## Implementation Note
In EXFINOPS, translations are managed in `assets/translations/`. The `AppLocalization` class handles loading and fallback to `tr`.
