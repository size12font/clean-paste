# CleanPaste Workspace

CleanPaste is a local macOS menu-bar utility that normalizes copied content into
one versioned plain-text contract before paste.

- Product and build instructions: [`CleanPaste/README.md`](CleanPaste/README.md)
- Implementation plan: [`docs/plans/2026-07-09-001-feat-cleanpaste-plan.md`](docs/plans/2026-07-09-001-feat-cleanpaste-plan.md)
- Build and launch: `./script/build_and_run.sh`
- Create shareable notarized installer: `./script/package_dmg.sh`

Release verification:

```bash
swift test --package-path CleanPaste
swift run --package-path CleanPaste CleanPasteQA
swift run --package-path CleanPaste CleanPasteTargetSmoke
swift run --package-path CleanPaste CleanPasteShortcutQA
./script/build_and_run.sh --verify
```
