# iOS Shortcut Fixture Checks

Generated: 2026-07-10T14:29:07Z

This executable check mirrors the documented Shortcut replacement chain. It does not claim that an iPhone trigger was automated from macOS.

| Fixture | ClipCore chars | Shortcut mirror chars | Result |
|---|---:|---:|---|
| `ai-chat/chatgpt-answer` | 79 | 79 | Pass |
| `code-editor/xcode-snippet` | 48 | 48 | Pass |
| `messaging/slack-message` | 62 | 62 | Pass |
| `social-editor/linkedin-post` | 110 | 110 | Pass |
| `webpage-form/comment-field` | 50 | 50 | Pass |

## Documented Limitation

The Shortcut must still be assembled and triggered on an iPhone to prove Back Tap, Share Sheet, or Action Button wiring. Header removal, Markdown links, tables, and HTML fallback remain ClipCore-only; common drift should trigger a small App Intent rather than more Shortcut regex.
