# CleanPaste Real-World Compatibility Report

Run date: 2026-07-10

## Status

Continuation update: 36 executable surfaces have real paste evidence, including 19 same-profile public/editor replacements. Fourteen primary rows remain blocked (auth or unavailable app target). Destination constraints are now separated from CleanPaste defects. Compatibility certification remains open pending blocked primary coverage.

## Baseline

- Swift tests: 49/49 pass.
- Canonical fixtures: 8/8 pass.
- Synthetic target combinations: 32/32 pass.
- iOS Shortcut mirror: 5/5 pass.
- App build/launch verification: pass.

## Results

- Frozen fixtures: 8/8.
- Fixture manifest hashes: 8/8 pass.
- Native AI Copy sources: ChatGPT F0/F1/F6; Gemini F2-F5/F7.
- Source-transform regressions: 3/3 fixed and covered by unit tests (nested lists, self-labeled URLs, family emoji joiners).
- Destination pilot: W01 completed 7/7 with six exact passes and one Claude-overlay auth block; W04 completed 3/3 with two pass/fallback-pass and one destination constraint; D01/D02 recovered and passed 7/7; W12 remains blocked by Slack auth.

## Findings

- Resolved P1/P2 source defects: self-labeled URL duplication, nested-list flattening, and family-emoji ZWJ removal.
- Environment: browser automation clipboard requires a deterministic macOS pasteboard bridge.
- Environment: desktop windows and screenshots are not accessible from current agent process.
- Environment: OS frontmost application is `com.apple.loginwindow`, preventing production target detection from observing Chrome/Slack activation.
- W01 Google Docs preserves F0/F2/F4/F5/F6 and Gemini-overlay F6G canonical text exactly after declared trailing-newline normalization; literal list markers survive save/reload. Claude overlay is blocked at source login.
- W04 Google Sheets grid paste maps tabular F7 into a correct 12x3 range and F0 into 4x1, but strips leading spaces from nested bullets and code-like lines in F6 (destination constraint).
- W02 Google Docs comments preserve F0/F2 exactly, but the F6 long-form case loses leading indentation and is truncated at the destination's 2000-character limit (destination constraint); no comment was posted.
- W03 Google Sheets single-cell editing preserves F0/F2/F5/F6/F6G exactly after decoding normal clipboard CSV quoting, but expands F4 tab characters to eight spaces (destination constraint).
- W06 Gmail body preserves basic/list text, but normalizes indentation to non-breaking spaces, tabs to ordinary spaces, and emoji to visual inline images omitted from plain-text copy-back (destination constraint).
- W07 Gmail subject strips every newline without inserting a separator, concatenating line boundaries; Unicode and emoji remain present (destination constraint for single-line field). QA draft was discarded.
- W09 ChatGPT and W11 Gemini prompt composers visually preserve lines, blank lines, list markers, Unicode, and emoji. Their contenteditable copy-back adds one newline per paragraph; collapsing paired newlines restores canonical text exactly. Nothing was submitted.
- W05 Google Slides and W27 Google Forms preserve all three tested fixtures exactly. The Form remained unpublished and no response was submitted.
- W10 Claude preserves ordinary lines and Unicode, but collapses intentional blank lines in list/Unicode fixtures (destination constraint). Nothing was submitted.
- D01/D02 TextEdit and D04 Pages preserve tested canonical cases. D03 Notes strips leading indentation/tabs in F4/F6 (destination constraint). D18 VS Code exact saved-file readback passes; D19 Xcode expands F4 tabs to four spaces (destination constraint).
- Replacement editors R01-R19 each preserve F0/F2/F5 exactly; evidence is labeled replacement and does not hide blocked primary rows.

## Completion Audit

- Primary matrix: 50 rows, 210 planned cases. Real execution now covers 17 primary surfaces plus 19 replacements; 14 primary surfaces remain blocked.
- Replacement coverage: 19 distinct public/editor surfaces, 57 additional cases, all exact F0/F2/F5 passes.
- Blocked primary outcomes: 135 cases (77 web auth, 58 native targets still unavailable); two source-overlay cases remain blocked.
- Real scored outcomes across primary + replacements: 132 cases, with destination constraints retained as limitations and no CleanPaste-owned failure rows.
- Pass/fallback gate: not met; remaining blocked primary rows prevent full certification, but no known CleanPaste-owned source defect remains.
- P0: 0. CleanPaste-owned P1/P2: 0. Destination constraints remain documented per surface.
- Tier-1 and full 50-surface compatibility certification: not achieved. Replacements are explicitly labeled; no blocked primary row is silently counted as pass.

## Validation Update

- Focused transform regression run: 19/19 passed.
- Full Swift suite: 49/49 passed.
- Canonical fixture QA: 8/8 passed.
- Targeted destination-evidence audit: 36 completed cases across W02 (3), W03 (7), W04 (3), W06 (5), W07 (3), W10 (3), D03 (5), and D19 (7).
- Raw-paste control artifacts are present for W03 F0/F2/F4/F5/F6/F6G and support its `destination_constraint` classification.
- Fresh production Command-V re-probes were not run in this session: available browser automation uses an isolated clipboard and cannot drive the macOS CleanPaste monitor or native app windows. Existing production evidence remains preserved; no new outcome is claimed.
- Final ledger counts: 25 `pass`, 3 `pass_with_destination_normalization`, 8 `destination_constraint`, 19 `blocked_auth`, and 14 `blocked_environment`. No `fail`, `fallback_fail`, or `fail_cleanpaste` rows remain.
