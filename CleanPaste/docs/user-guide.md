# CleanPaste User Guide

CleanPaste runs locally as a macOS menu-bar utility.

## Clean Clipboard

1. Copy text from an app that provides plain text or recoverable HTML.
2. Open CleanPaste from the menu bar.
3. Choose **Clean clipboard now**.
4. Review the preview, then paste normally.

When matching plain text and HTML are available, CleanPaste uses HTML block
structure to restore paragraph and heading breaks that plain clipboard text can
lose. The preview is the text contract: target apps should preserve its paragraphs,
blank lines, links, and code-like lines. Numbered and bulleted lines also carry
minimal semantic HTML so Slack and other rich editors can create actual lists.
Plain-text fields keep the visible markers. Bold, italics, colors, fonts, and
other source styling are intentionally removed.

CleanPaste adapts list output when the destination app becomes active. Slack
receives semantic ordered and unordered lists. Browser-based editors such as
LinkedIn receive literal `1.` and `-` markers, so list structure survives even
when the editor has no native list support. Unknown destinations use literal
markers as the safe fallback.

## Clean And Paste

Choose **Clean and paste** or press Command-Shift-V. With Accessibility
permission, CleanPaste sends Command-V to the focused app after cleaning. If
permission is denied or synthetic paste fails, the clean text remains on the
clipboard and the status asks you to press Command-V manually.

Unsupported or empty clipboards fail before CleanPaste clears existing content.

## Target Differences

CleanPaste verifies behavioral target classes: native text, web textarea, web
contenteditable, and rich composer. A named app is recorded only when it
reproducibly mutates canonical content. See `qa/app-regressions.md`.
