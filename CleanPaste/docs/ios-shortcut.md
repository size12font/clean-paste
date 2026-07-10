# iOS Shortcut Mirror

iOS v1 is a Shortcut mirror, not a full app.

Shortcut chain:

1. Get Clipboard.
2. Replace non-breaking, narrow non-breaking, and thin spaces with normal spaces.
3. Remove zero-width characters.
4. Remove common Markdown emphasis markers and code fences.
5. Remove trailing spaces while preserving leading code/list indentation.
6. Collapse three or more line breaks to two.
7. Copy result to Clipboard.

Triggers:

- Back Tap
- Share Sheet
- Action Button or Lock Screen shortcut

Known limitation: Shortcut regex is intentionally simpler than ClipCore. Compare
top fixtures against ClipCore and document drift instead of expanding Shortcut
complexity too far.

Run the rule-mirror check from the workspace root:

```bash
swift run --package-path CleanPaste CleanPasteShortcutQA
```

This verifies the documented replacement chain against five mobile-safe
fixtures. It does not automate an iPhone. Back Tap, Share Sheet, and Action
Button wiring remain a device spot check. Header removal, Markdown links,
tables, and HTML fallback remain ClipCore-only; common drift should move the
shared transform into a small App Intent.
