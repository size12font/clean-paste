# Slack Semantic Lists

Reported: 2026-07-10

## Reproduction

1. Clean text containing `1. Item` or `- Item` lines.
2. Paste into Slack's rich message composer.
3. Observe literal marker characters instead of native list formatting.

## Cause

CleanPaste v0.1 wrote only plain text. Plain text preserves visible markers but
cannot express ordered-list or unordered-list semantics.

## Resolution

List-bearing content now includes canonical plain text plus minimal semantic
HTML using `<ol>`, `<ul>`, and `<li>`. Non-list content remains plain-only.

Automated coverage verifies:

- ordered and bulleted clipboard HTML;
- HTML escaping inside list items;
- semantic lists in WebKit contenteditable targets;
- attributed text-list semantics in AppKit rich composers;
- unchanged plain-text fallback in native text and textarea targets.
