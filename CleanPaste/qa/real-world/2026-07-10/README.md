# CleanPaste Real-World Compatibility Campaign

Run date: 2026-07-10

Canonical plan: `docs/plans/2026-07-10-002-qa-cleanpaste-50-surface-plan.md`

This folder is source of truth for 50-surface real-user QA. Synthetic harness reports remain separate under `CleanPaste/qa/`.

## Status

- Baseline: complete.
- Fixture freeze: complete (8/8).
- Five-surface pilot: complete with documented blockers.
- Primary matrix: 50 rows / 210 planned cases retained.
- Real execution: 17 primary surfaces plus 19 explicitly labeled replacements; 14 primary surfaces remain blocked.
- Final audit: source defects remediated; certification remains incomplete only because primary auth/environment blockers remain.

## Rules

- Synthetic content only.
- Never send, publish, submit, or modify existing user/team content.
- Clipboard and focus tests run serially.
- CleanPaste preview is oracle.
- Blocked primary surfaces remain recorded even when replaced.
