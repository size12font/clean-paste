# CleanPaste

CleanPaste is a local macOS menu-bar utility for paste-stable clean content.

It selects a recoverable clipboard representation, normalizes structure, shows
the canonical preview, clears source formatting, and writes a plain-text
fallback. When numbered or bulleted lists are present, it also writes minimal
semantic HTML so rich editors create actual lists. Bold, colors, fonts, and
other source styling remain removed.

## Use

1. Keep CleanPaste running in the menu bar.
2. Copy text in any app that provides plain text or HTML. CleanPaste immediately
   replaces the clipboard contents with cleaned text.
3. Paste normally with Command-V. No CleanPaste click or special paste action is
   required.
4. Open the menu only when you want to inspect the cleaned preview.

The optional global shortcut is Command-Shift-V. Automatic cleaning and normal
Command-V paste do not require Accessibility permission.

## Verify

From the workspace root:

```bash
swift test --package-path CleanPaste
swift run --package-path CleanPaste CleanPasteQA
swift run --package-path CleanPaste CleanPasteTargetSmoke
swift run --package-path CleanPaste CleanPasteShortcutQA
./script/build_and_run.sh --verify
```

`CleanPasteQA` verifies all source fixtures against `CanonicalPaste` and checks
safe clipboard payloads. `CleanPasteTargetSmoke` runs every preview through
native text, web textarea, web contenteditable, and rich composer harnesses.
Named applications are optional spot checks, not matrix columns.

## Share with Beta Testers

The shareable installer is a Developer ID-signed and Apple-notarized DMG:

```bash
./script/package_dmg.sh
```

See [release instructions](docs/release.md) for the one-time Apple credential
setup and tester install steps. `--local-only` is for this Mac only and must
not be shared.

## Fixture Capture

Checked fixtures are non-sensitive live captures from controlled AppKit and
WebKit source harnesses. Refresh them explicitly:

```bash
swift run --package-path CleanPaste CleanPasteFixtureCapture --confirm-nonsensitive
```

For an external source, `tools/dump-pasteboard.swift` records metadata and
redacts payloads by default. Pass `--full` only for known non-sensitive text;
only full non-sensitive captures can enter executable release conformance.

## Layout

- `Sources/ClipCore`: canonical contract, source extractors, transform, and target capability declarations.
- `CleanPasteMac/CleanPasteMacCore`: pasteboard, permission, hotkey, and preview services.
- `CleanPasteMac/CleanPasteMac`: menu-bar SwiftUI app.
- `Tools`: source, target, fixture-capture, and Shortcut verification tools.
- `qa`: live fixture evidence, conformance reports, capability declarations, and regression policy.
- `docs`: user, privacy, permission, release, and iOS Shortcut documentation.
