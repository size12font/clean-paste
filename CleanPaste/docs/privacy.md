# Privacy

CleanPaste runs locally and sends no clipboard content to external services.

The app reads pasteboard types and in-memory textual representations only when
the user invokes a clean action. It writes one plain-text representation. macOS
may also advertise the equivalent legacy `NSStringPboardType` alias; CleanPaste
does not write HTML, RTF, files, or app-specific data.

`tools/dump-pasteboard.swift` records metadata and redacts text by default.
`--full` requires an explicit choice and should be used only for non-sensitive
samples. The checked fixtures were refreshed from controlled AppKit/WebKit
harnesses using known non-sensitive text and explicit confirmation.

Running target QA temporarily uses the general pasteboard and restores all
original pasteboard item data afterward. Normal cleaning deliberately replaces
the clipboard. Universal Clipboard may sync that replacement to the user's
other Apple devices.
