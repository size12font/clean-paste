---
title: CleanPaste 50-Surface Real-World QA Plan
date: 2026-07-10
type: qa
execution: knowledge-work
status: ready
---

# CleanPaste 50-Surface Real-World QA Plan

## Outcome

Run a real-user compatibility census across 50 distinct paste destinations: 30 browser surfaces and 20 installed macOS surfaces. Use actual AI-product Copy buttons, production CleanPaste behavior, reproducible fixtures, semantic assertions, screenshots, DOM/accessibility evidence, and raw-paste controls.

This campaign supplements existing synthetic release gates. It does not replace the four behavioral target classes in `CleanPaste/qa/target-capabilities.md` or turn named apps into permanent release-matrix columns. A named destination becomes a product regression only after repeatable evidence shows CleanPaste violates its canonical preview contract.

Estimated effort: 16-22 active QA hours across 2-3 working days, excluding authentication/CAPTCHA blockers.

---

## Product Grounding

CleanPaste behavior already defines the oracle:

- CleanPaste preview is expected output. Compare destination against preview, not original AI rich rendering.
- Source bold, italic, colors, fonts, Markdown fences, and similar style noise are intentionally stripped.
- Paragraph order, blank lines, visible list structure, numbering, links, code-like lines, tables degraded to readable text, Unicode, and exact words must survive.
- Production target adaptation emits semantic HTML lists only for Slack native or a recognized Slack browser window. Other destinations receive literal `-` and `1.` markers.
- Automatic cleaning and destination adaptation both poll every 0.2 seconds. Focus-switch timing is part of QA.
- Existing `CleanPasteTargetSmoke` proves synthetic AppKit/WebKit classes, but it uses semantic list mode broadly. It does not reproduce production destination detection or real site/app behavior.

Known high-risk seams:

1. Slack semantic lists versus literal-marker fallback everywhere else.
2. Nested/mixed lists, discontinuous numbering, and list/paragraph spacing.
3. Destination activation followed by an immediate paste before the 0.2-second adaptation poll.
4. Browser window-title detection for Slack.
5. Rich targets whose rendered text differs while remaining semantically correct.
6. Single-line and grid controls that cannot preserve normal multiline structure.
7. Copy-back evidence being re-cleaned by CleanPaste's clipboard monitor.

---

## Scope

### Included

- Exactly 50 completed, non-duplicate destination surfaces.
- Actual ChatGPT Copy-button output as primary source.
- Gemini and Claude Copy-button overlays on representative destinations.
- Normal Command-V production path on every surface.
- Command-Shift-V, rapid switch/paste, paste-without-formatting, or raw-paste controls where they answer a failure.
- Visible render, semantic structure, text integrity, blur persistence, and save/reload persistence where safe.
- Compatibility report, case ledger, screenshots, DOM/accessibility capture, diffs, blocker log, and reproducible regression packages.

### Excluded

- Sending messages, email, comments, or posts.
- Publishing content or editing existing personal/team documents.
- Password, payment, account-setting, production CMS, or shell-prompt fields.
- New accounts, app installs, auth-scope expansion, or permission grants solely for QA.
- Product fixes. This run diagnoses and reports. Fixes require a separate implementation request.

---

## Frozen AI Fixture Pack

Generate each fixture once in ChatGPT, verify it visually, then freeze its exact displayed output and Copy-button payload. Every block gets a unique neutral token so loss, duplication, and reordering are detectable.

| ID | Purpose | Required content |
|---|---|---|
| F0 | Integrity control | Short ASCII lines, repeated word, punctuation, unique token per line. |
| F1 | Whitespace | Two paragraphs, hard break, intentional blank line, 3+ blank lines, long visually wrapped line. |
| F2 | Lists | Bullets, two nesting levels, multiline item, ordered list, non-1 start, mixed nesting. |
| F3 | Source-style stripping | H2/H3, bold, italic, strike, inline code, labeled link, bare URL. |
| F4 | Complex blocks | Blockquote, fenced code with indentation/blank line, 3x3 table, checklist, horizontal rule. |
| F5 | Unicode | Hangul, Japanese, Arabic RTL, accents/combining marks, emoji/ZWJ, smart quotes, en/em dashes. |
| F6 | Real AI answer | 200-300 words combining intro, headings, nested bullets, ordered steps, link, code, closing paragraph. |
| F7 | Constrained targets | Safe single-line text, spreadsheet rows/cells, literal-list fallback, code indentation. |

Store four immutable fixture views:

- Original rendered AI response.
- Raw provider clipboard types and hashes, captured once with CleanPaste quit.
- CleanPaste canonical preview/plain text.
- Semantic manifest: block order, paragraph count, newline count, list type/depth/order, link targets, code lines, table cells, Unicode tokens.

Raw provider capture uses only synthetic content. Full payload capture is allowed only for these controlled fixtures.

---

## Oracle and Ratings

### Expected behavior by destination profile

| Profile | Pass behavior |
|---|---|
| Rich/block editor | Words/order/paragraphs match preview. Literal markers may remain or become equivalent native lists. No source font/color/style leakage. |
| Slack rich composer | Ordered/unordered list semantics render natively; item order, nesting, numbering, and surrounding paragraphs remain correct. |
| Markdown editor | Canonical characters remain readable. Destination preview/save must not lose or reorder content. CleanPaste-stripped Markdown is not expected to reappear. |
| Plain multiline/chat | Exact words/order/newlines; literal bullets/numbers remain visibly recognizable; no accidental send. |
| Source editor | Exact canonical characters, indentation, blank lines, Unicode, and line endings; no execution. |
| Single-line field | No accidental submit, hidden control characters, duplication, or word concatenation. Rejected/collapsed newlines are recorded as destination constraint, not silently called success. |
| Grid/cell | Cell-edit mode and grid-paste mode use separately declared expectations. Ordinary prose must not spill unexpectedly; table fixture may intentionally map tabs/newlines to cells. |
| Canvas text | Text order, paragraph/list readability, indentation, and overflow remain inspectable. |

### Scoring

Score only applicable dimensions:

| Dimension | Weight |
|---|---:|
| Text integrity: no loss, duplication, mutation, or reorder | 35 |
| Paragraphs, blank lines, and hard breaks | 25 |
| List type, hierarchy, indentation, and numbering | 25 |
| Links, code/table/quote fallback readability | 10 |
| No source-style leakage or visual artifacts | 5 |

Statuses:

- **Pass:** score >=95, all critical assertions pass, no P0/P1.
- **Fallback pass:** score >=95 under a predeclared limited-capability oracle.
- **Fail:** score <95 or any critical assertion fails.
- **Blocked:** auth, CAPTCHA, permission, unavailable editor, or unsafe target.
- **Not run:** never merged with Blocked.

Automatic critical failures:

- Missing, duplicated, mutated, or reordered content.
- Wrong link target.
- Meaning-changing code indentation or line corruption.
- Clipboard contamination across cases.
- Crash, hang, unintended send/publish/save, or privacy exposure.

Severity:

- P0: crash, destructive action, privacy leak, unintended communication.
- P1: data loss/duplication/reorder, wrong link, widespread core formatting failure.
- P2: isolated semantic loss with readable content.
- P3: cosmetic spacing/style difference.

---

## 50-Surface Matrix

“Surface” means destination plus editor mode with materially distinct paste behavior. Two modes in one product count only when behavior differs, such as Sheets cell edit versus grid paste.

### Browser surfaces: 30

| ID | Surface | Profile | Tier | Main risk |
|---:|---|---|---:|---|
| W01 | Google Docs document body | Rich editor | 1 | Paragraph gaps, literal/native lists, links. |
| W02 | Google Docs comment | Limited rich/chat | 2 | Compact composer line breaks and list fallback. |
| W03 | Google Sheets single-cell edit | Grid/cell | 1 | Embedded newlines versus cell escape. |
| W04 | Google Sheets grid paste | Grid/cell | 3 | Tabs/newlines splitting across rows and columns. |
| W05 | Google Slides text box | Canvas text | 2 | Paragraph/list autoformat and overflow. |
| W06 | Gmail compose body | Rich editor | 1 | HTML/paragraph interpretation and signature boundary. |
| W07 | Gmail subject | Single line | 3 | Newline collapse, truncation, no accidental send. |
| W08 | Notion web page body | Block editor | 1 | Block creation, blank blocks, lists, code/table fallback. |
| W09 | ChatGPT web prompt composer | Chat composer | 2 | Multiline and literal markers; no send. |
| W10 | Claude web prompt composer | Chat composer | 2 | Multiline and literal markers; no send. |
| W11 | Gemini web prompt composer | Chat composer | 2 | Multiline and literal markers; no send. |
| W12 | Slack web channel composer | Slack rich composer | 1 | Window-title detection, semantic lists, fast-paste race. |
| W13 | Discord web message composer | Chat/Markdown | 1 | Newline/send behavior, markers, code fallback. |
| W14 | LinkedIn post composer | Plain multiline | 1 | Literal bullets, paragraph gaps, long-post behavior. |
| W15 | LinkedIn comment composer | Limited/plain | 3 | Compact-field newline and marker behavior. |
| W16 | X post composer | Plain multiline | 3 | Character limit, URLs/emoji, newline preservation. |
| W17 | Reddit Fancy Pants post editor | Rich editor | 1 | Rich conversion, paragraphs, lists, code/quote fallback. |
| W18 | Reddit Markdown post editor | Markdown editor | 2 | Literal canonical text versus rendered preview. |
| W19 | GitHub issue body | Markdown editor | 1 | Paragraphs, lists, code, table degradation. |
| W20 | Stack Overflow question editor | Markdown editor | 2 | Preview parity, code indentation, lists. |
| W21 | Linear issue description | Rich/Markdown | 1 | Lists, links, code, blur persistence. |
| W22 | Trello card description | Markdown editor | 2 | Save/preview conversion and blank lines. |
| W23 | Medium story editor | Rich editor | 2 | Paragraph versus soft break, list indentation. |
| W24 | Substack post editor | Rich editor | 2 | Newsletter paragraph/list HTML and draft persistence. |
| W25 | WordPress Gutenberg canvas | Block editor | 2 | Paragraph/list/code/table block mapping. |
| W26 | Canva Docs page body | Rich/block editor | 2 | Heading/list conversion and unsupported-block fallback. |
| W27 | Google Forms paragraph answer | Plain multiline | 2 | Newlines, markers, tabs, code/table flattening. |
| W28 | Typeform short-answer field | Single line | 3 | Rejection/collapse and accidental-submit safety. |
| W29 | Airtable long-text cell | Grid/rich | 3 | One-cell versus range split; tabs/newlines. |
| W30 | Figma comment composer | Limited/plain | 3 | Compact multiline, markers, no comment submission. |

### Installed macOS surfaces: 20

These apps were present during plan recon. Recheck versions and availability before execution.

| ID | Surface | Profile | Tier | Main risk |
|---:|---|---|---:|---|
| D01 | TextEdit plain-text document | Native plain | 1 | Exact canonical baseline. |
| D02 | TextEdit rich-text document | Native rich | 1 | HTML flavor choice and list interpretation. |
| D03 | Apple Notes note body | Native rich | 1 | Paragraphs, blank lines, list autoformat. |
| D04 | Apple Pages document body | Native rich | 1 | Lists, indentation, links, table fallback. |
| D05 | Apple Mail compose body | Native rich | 1 | Paragraph/list HTML and signature boundary. |
| D06 | Apple Messages draft composer | Chat/plain | 2 | Multiline behavior and no send. |
| D07 | Slack desktop channel composer | Slack rich composer | 1 | Semantic lists and activation timing. |
| D08 | Discord desktop message composer | Chat/Markdown | 1 | Electron parity, newlines, code fallback. |
| D09 | Telegram desktop draft composer | Chat/plain | 2 | Newlines, visible markers, no send. |
| D10 | KakaoTalk desktop draft composer | Chat/plain | 2 | Hangul/Unicode, markers, no send. |
| D11 | LINE desktop draft composer | Chat/plain | 2 | Newlines, markers, no send. |
| D12 | Notion desktop page body | Block editor | 1 | Desktop/web parity and block conversion. |
| D13 | Apple Numbers single-cell edit | Grid/cell | 3 | Embedded line breaks within one cell. |
| D14 | Apple Numbers grid paste | Grid/cell | 3 | Tab/newline range mapping. |
| D15 | Apple Keynote text box | Canvas text | 2 | Bullets, numbering, indentation, overflow. |
| D16 | Apple Freeform text box | Canvas text | 2 | Paragraph/list readability and object sizing. |
| D17 | Obsidian Source Mode editor | Markdown/source | 1 | Exact canonical text, indentation, Unicode. |
| D18 | Visual Studio Code scratch editor | Source editor | 1 | Exact characters, tabs/spaces, line endings. |
| D19 | Xcode scratch source editor | Source editor | 2 | Auto-indent interaction and Unicode. |
| D20 | Finder filename rename field | Single line | 3 | Newline/tab rejection, no accidental rename commit. |

Blocked primary rows remain in the ledger. Replace them to reach 50 completed surfaces with same-profile fallbacks: Discourse topic composer, Asana task description, Facebook draft post, Apple Stickies, Reminders notes, Calendar event notes, Cursor scratch editor, or Beeper draft composer.

---

## Case Count

| Layer | Coverage | Cases |
|---|---:|---:|
| Core census | F0 + F6 + one profile-specific fixture on all 50 surfaces | 150 |
| Tier-1 depth | Two additional edge fixtures on 20 Tier-1 surfaces | 40 |
| Source overlay | F6 copied from Gemini and Claude on 10 representative surfaces | 20 |
| **Planned total** | Before retries and blocker replacements | **210** |

Optional stretch after core completion:

- Repeat 10 web surfaces in Safari or a second browser.
- Manual selection-copy versus provider Copy button on 8 representative surfaces.
- AI Copy-code button on 6 source/code destinations.
- Command-Shift-V versus normal Command-V on 10 representative surfaces.
- Immediate target switch/paste versus 0.5-second settled paste on Slack and other high-risk targets.

---

## Execution Protocol

### Phase 0: Freeze build and baseline

1. Record macOS version, CleanPaste app bundle version/build timestamp/hash, browser/app versions, and current workspace state. No commit SHA is assumed because this repository currently has no commits.
2. Run existing unit, canonical-fixture, target-smoke, shortcut, and app-bundle verification gates.
3. Save baseline reports. Existing green harness results are prerequisites, not proof of real destinations.
4. Capture actual raw ChatGPT/Gemini/Claude Copy-button formats once with CleanPaste quit; relaunch before production-path cases.

### Phase 1: Prepare safe scratch targets

1. Use current signed-in browser session and installed apps only.
2. Create blank private artifacts named `QA DO NOT SEND - CleanPaste - <date>` when a surface requires a document.
3. Use draft-only chat/email/social composers. Never send, publish, submit, comment, merge, or edit existing content.
4. Preflight all 50 primary surfaces. Mark blockers before case execution and reserve same-profile replacements.
5. Freeze fixtures, semantic manifests, and expected CleanPaste previews.

### Phase 2: Five-surface pilot

Pilot one surface from each core behavior family:

- D01 TextEdit plain.
- D02 TextEdit rich.
- W01 Google Docs body.
- W12 Slack web composer.
- W04 Google Sheets grid paste.

Validate focus checks, target adaptation delay, DOM/accessibility extraction, screenshots, diff rules, and cleanup. Do not scale to remaining 45 until pilot evidence is trustworthy.

### Phase 3: Browser census

Run six sequential batches of five surfaces. Clipboard and focus are global state; do not parallelize UI pastes.

Per case:

1. Reset destination to empty scratch state.
2. Activate AI source, invoke native Copy, wait for CleanPaste preview to settle.
3. Capture preview, canonical clipboard types/hashes, and transform version.
4. Activate exact destination and focus exact editor role.
5. Wait 0.5 seconds for normal-path target adaptation unless case explicitly tests rapid paste.
6. Capture post-adaptation clipboard types/hashes without changing clipboard.
7. Paste once with Command-V.
8. Capture visible output, DOM/block tree, editor value, screenshot, and after-blur state.
9. For Tier-1 persistent editors, verify safe draft save/reload or reopen behavior.
10. Clear destination without sending/publishing. Set clipboard to benign synthetic text.

### Phase 4: Desktop census

Run four sequential batches of five. Before every paste, assert frontmost app/window and focused accessibility role.

Prefer accessibility values, saved scratch-file inspection, or app-specific document APIs over copy-back. Copy-back while CleanPaste runs would be re-cleaned and contaminate evidence. When copy-back is essential:

1. Preserve after-paste screenshot and accessibility state.
2. Quit CleanPaste after paste.
3. Copy output back from destination and capture it.
4. Relaunch CleanPaste and recopy frozen source before next case.

### Phase 5: Extended and source-overlay cases

1. Run two extra edge fixtures on all Tier-1 surfaces.
2. Repeat F6 from Gemini and Claude on 10 representative surfaces spanning rich, Slack, plain, Markdown, source, grid, and single-line profiles.
3. Run rapid switch/paste cases around the 0.2-second adaptation boundary.
4. Run browser-title variations for Slack web to test recognition.

### Phase 6: Failure reproduction and attribution

On first mismatch:

1. Freeze evidence before changing state.
2. Reset into a fresh empty target.
3. Repeat twice using same canonical clipboard fingerprint.
4. Failure in at least 2/3 attempts is reproducible.
5. Failure in 1/3 triggers two more attempts; report intermittent rate over five.
6. Quit CleanPaste, recopy same frozen AI response, and run one raw-paste control.
7. Run paste-without-formatting control where supported.
8. Recopy source only after fixed-payload retries; compare source clipboard hashes.
9. Use alternate AI provider once when source-specific behavior is suspected.

Attribution rules:

- Raw and CleanPaste both fail: source/destination limitation likely.
- Raw passes and CleanPaste fails: CleanPaste path likely.
- Source hashes change between copies: provider variability.
- Immediate output passes but blur/reload fails: destination serialization interaction.
- Settled paste passes but rapid paste fails: target-adaptation race.
- Only one paste invocation path fails: shortcut/context-menu integration issue.

### Phase 7: Consolidate and rerun

1. Classify every failure: CleanPaste, source provider, destination constraint, environment/auth, focus race, or intermittent.
2. Create `qa/regressions/<app>/<case>/` evidence only for repeatable CleanPaste-owned failures.
3. Do not implement fixes during this QA run.
4. After separately authorized fixes, rerun failed case, affected capability class, five-surface sentinel set, then full 50-surface census before closure.

---

## Evidence Contract

Store campaign artifacts under `CleanPaste/qa/real-world/2026-07-10/`:

```text
fixtures/
  F0-F7 source, preview, manifest, clipboard metadata
surface-ledger.csv
cases/
  <case-id>/
    case.json
    expected.txt
    actual.txt
    diff.txt
    after-paste.png
    after-blur.png
    dom-or-ax.json
    clipboard-before.json
    clipboard-after-target.json
compatibility-report.md
blockers.md
artifact-cleanup.md
```

Case ID format:

`CP-<run>-<surface>-<fixture>-<source>-<paste-path>-A<attempt>`

Each case records:

- Timestamp; macOS, app/browser, and destination versions.
- Destination URL/app, editor mode, profile, and tier.
- AI provider, frozen source ID, and copy method.
- CleanPaste build hash, transform version, target list mode, activation/paste timing.
- Clipboard flavor hashes before paste and after target activation.
- Expected semantic assertions and actual semantic capture.
- Immediate, after-blur, and safe after-reload result where applicable.
- Score, status, severity, attribution, retry count, and notes.

Failure evidence adds raw-paste control, paste-without-formatting control, reproduction rate, and short cropped/redacted recording when motion/focus matters.

---

## Safety and Privacy

- Synthetic fixture content only. No personal, customer, company, credential, medical, legal, or financial text.
- Blank private scratch artifacts only; never paste into existing user/team content.
- Never press Send, Publish, Submit, Comment, Merge, or production Save.
- No shell prompts. Code fixtures go into inert scratch editors.
- Focus assertion before every paste. P0 safety event stops current batch.
- Crop/redact screenshots so nearby private content never enters evidence.
- Clear clipboard to benign synthetic text after each batch.
- Inventory every QA artifact. Cleanup may remove only artifacts created by this run.

---

## Completion Gate

QA is complete only when:

- 50 non-duplicate surfaces have completed cases; blockers were replaced without hiding original blockers.
- All 210 planned primary cases are Pass, Fallback pass, Fail, or Blocked—none silently missing.
- 100% of Tier-1 surfaces pass or have an explicit accepted destination constraint.
- Zero unresolved P0/P1 CleanPaste failures.
- At least 95% of completed cases are Pass or Fallback pass.
- Every failure has reproduction evidence and attribution.
- Slack semantic-list behavior is verified in native and web composers, including rapid-switch and window-title cases.
- Literal-marker fallback remains readable across plain, chat, Markdown, source, single-line, grid, and canvas destinations.
- Final report distinguishes synthetic harness proof from real-world evidence.
- Clipboard ends with benign text; no unsent QA content or scratch artifact remains untracked.

---

## Deliverables

1. Frozen actual-AI Copy-button fixture pack.
2. 50-surface ledger and 210-case result matrix.
3. Evidence folder with screenshots, semantic captures, clipboard fingerprints, and diffs.
4. Compatibility report: strongest surfaces, acceptable constraints, failures, blocked targets, and target-capability gaps.
5. Reproducible regression packages for CleanPaste-owned failures.
6. Separate recommended-fix backlog, ranked P0-P3, without changing product code during QA.

## Assumptions

- Current signed-in browser state supplies enough private scratch editors; blocked sites get same-profile replacements.
- Existing app permissions remain unchanged. Missing permissions become blockers unless user explicitly grants them during execution.
- Normal user behavior means target activation settles for 0.5 seconds before paste; separate rapid-paste cases test the race boundary.
- Current target contract remains preview-first and structure-only. Rich source styling is intentionally out of scope.
