# Baseline

Captured: 2026-07-10 13:15 KST

## Environment

- macOS: 26.5.1 (25F80), arm64.
- Git branch: `feat/cleanpaste`.
- Git state: no commits; workspace files untracked.
- Accessibility UI scripting: enabled.
- Chrome: 149.0.7827.158.
- CleanPaste runtime: `dist/CleanPasteMac.app` debug bundle.
- CleanPaste executable SHA-256: `0b45ef407a8dee4109404b42f076244b82a41c125e2bd87290ee85a18dd8cb9e`.
- Bundle timestamp: 2026-07-10T13:14:59+0900.
- Signature: ad hoc; bundle has no version fields.

## Existing gates

| Gate | Result | Evidence |
|---|---|---|
| Swift tests | Pass | 43/43 tests, 0 failures. |
| Canonical source conformance | Pass | 8/8 fixtures. |
| Target capability smoke | Pass | 32/32 synthetic combinations. |
| iOS Shortcut mirror | Pass | 5/5 fixtures. |
| App build/launch verification | Pass | `script/build_and_run.sh --verify` exited 0; runtime PID observed. |

These gates prove deterministic internal contracts. They do not prove named websites/apps or production target detection.

## Installed desktop targets

| App | Version |
|---|---|
| TextEdit | 1.20 |
| Notes | 4.13 |
| Pages | 14.5 |
| Mail | 16.0 |
| Messages | 26.0 |
| Slack | 4.50.143 |
| Discord | 0.0.394 |
| Telegram | 6.9.3 |
| KakaoTalk | 26.5.0 |
| LINE | 26.3.0 |
| Notion | 7.24.0 |
| Numbers | 14.5 |
| Keynote | 14.5 |
| Freeform | 4.5 |
| Obsidian | 1.12.7 |
| Visual Studio Code | 1.121.0 |
| Xcode | 26.4.1 |
| Finder | 26.4 |

