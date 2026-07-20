# Contributing

Thanks for helping improve CleanPaste.

## Development

```bash
swift test --package-path CleanPaste
./script/build_and_run.sh --verify
```

Changes to clipboard transforms should include a focused regression test and, when applicable, a non-sensitive conformance fixture. Run the wider QA executables before opening a pull request:

```bash
swift run --package-path CleanPaste CleanPasteQA
swift run --package-path CleanPaste CleanPasteShortcutQA
```

## Privacy rules

- Never commit real passwords, tokens, private messages, or personal clipboard captures.
- Prefer synthetic text that reproduces the same structure.
- External captures must follow the redaction and confirmation rules in `CleanPaste/README.md`.

Keep pull requests focused and explain the source content, target app, expected result, and actual result for paste regressions.
