# Release Plan

Initial distribution target: a direct-download beta DMG, signed with Developer
ID and notarized by Apple. Mac App Store and TestFlight are deferred. The app
supports macOS 14 and later.

## Local Installer

Create a shareable release-mode installer from the workspace root:

```bash
./script/package_dmg.sh
```

The command requires:

- an Apple Developer Program membership and a `Developer ID Application`
  certificate installed in Keychain;
- a notarization keychain profile named `CleanPaste` (or pass
  `--notary-profile PROFILE`).

It signs the app with hardened runtime, notarizes and staples the app, packages
the DMG, then notarizes and staples the DMG. It fails instead of producing a
misleading file when those release credentials are unavailable.

For local smoke testing only:

```bash
./script/package_dmg.sh --local-only
```

Do not send a `--local-only` DMG to beta testers: macOS will show an
unidentified-developer warning.

## Beta Tester Handoff

Send `dist/release/CleanPaste-<version>.dmg`. Ask testers to:

1. Open the DMG and drag **CleanPaste** into **Applications**.
2. Launch it from Applications; it appears as a menu-bar icon.
3. Copy and paste normal text once to confirm automatic clipboard cleaning.
4. If using the optional automatic Command-Shift-V action, enable CleanPaste in
   **System Settings > Privacy & Security > Accessibility**. Normal Command-V
   does not need that permission.
5. Report macOS version, target app, original text type, expected result, actual
   result, and a screenshot for failures. Never send sensitive clipboard data.

## Release Gates

Run from the workspace root:

```bash
swift test --package-path CleanPaste
swift run --package-path CleanPaste CleanPasteQA
swift run --package-path CleanPaste CleanPasteTargetSmoke
swift run --package-path CleanPaste CleanPasteShortcutQA
./script/build_and_run.sh --verify
```

Required evidence:

- at least eight live controlled source captures with manually authored previews;
- every source fixture matches its versioned `CanonicalPaste` output;
- pasteboard output always contains canonical plain text;
- list content also contains minimal semantic HTML with matching `<ol>`/`<ul>` structure;
- non-list content contains no HTML or RTF;
- all four target capability classes preserve every canonical preview;
- permission denial and synthetic-paste failure retain clean manual paste;
- privacy and fixture-capture behavior match documentation.

Named application checks are optional. A reproducible capability violation must
be recorded under `qa/regressions/` before any app-specific profile is proposed.
Original clipboard restore remains disabled until timing is measured safely.
