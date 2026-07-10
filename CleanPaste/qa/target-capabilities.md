# Target Capabilities

Release conformance is behavioral. It does not enumerate applications.

| Kind | Plain-text fallback | Semantic lists | Preserves newlines | Maximum length | Known mutations |
|---|---|---|---|---|---|
| `native_text` | Yes | Not consumed | Yes | None in harness | None observed |
| `web_textarea` | Yes | Not consumed | Yes | None in harness | None observed |
| `web_contenteditable` | Yes | `<ol>`/`<ul>` | Yes | None in harness | Semantic list rendering omits literal markers from extracted text. |
| `rich_composer` | Yes | Attributed text lists | Yes | None in harness | Visual indentation and marker style may differ. |

`TargetCapability.releaseGate` is the executable declaration. The
`CleanPasteTargetSmoke` tool runs every canonical source fixture through all
four classes.

Plain-text targets consume the canonical fallback. Rich targets may consume the
minimal HTML flavor when semantic lists are present.
