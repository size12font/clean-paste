# CleanPaste Fixtures

Each fixture stores actual pasteboard evidence, a non-sensitive source payload,
and a manually authored canonical preview.

Required files:

- `observed-formats.json`: live pasteboard types, source harness, lengths, and privacy mode;
- `raw/plain.txt` or `raw/source.html`: captured non-sensitive textual representation;
- `expected-preview.txt`: human-authored canonical CleanPaste output.

The checked fixtures use controlled AppKit and WebKit copy surfaces across AI
chat, browser selection, rich document, social editor, messaging, code editor,
web form, and HTML-only categories. Refresh all fixtures only when their source
text is known to be non-sensitive:

```bash
swift run --package-path CleanPaste CleanPasteFixtureCapture --confirm-nonsensitive
```

Capture an external source with redaction by default:

```bash
swift tools/dump-pasteboard.swift --output qa/fixtures/<category>/<case>
```

Pass `--full` only for non-sensitive content. Then replace the generated preview
placeholder manually. A redacted capture is safe evidence but is not executable;
release conformance accepts only controlled live captures or explicit
`external-full` fixtures with non-sensitive raw text. Then run:

```bash
swift run --package-path CleanPaste CleanPasteQA
swift run --package-path CleanPaste CleanPasteTargetSmoke
```
