# Source Transform Findings

Post-remediation status: all three CleanPaste-owned findings fixed and covered by `CleanPasteTransformTests`.

All three CleanPaste-owned findings reproduced 3/3 using identical raw MIME hashes.

| Finding | Severity | Fixture | Expected | Observed | Attribution |
|---|---|---|---|---|---|
| CP-SRC-001 Nested list hierarchy flattened | P2 | F2 Gemini | Nested `F2_B2A`/`F2_B2B` remain children of `F2_B2`. | Fixed: depth-aware HTML list extraction preserves nested indentation. | Resolved in CleanPaste source extraction. |
| CP-SRC-002 Self-labeled bare URL duplicated | P1 | F3 Gemini | One visible `https://example.org/f3`. | Fixed: self-labeled Markdown links emit URL once. | Resolved in CleanPaste Markdown link degradation. |
| CP-SRC-003 Family emoji decomposed | P2 | F5 Gemini | One family emoji `👨‍👩‍👧‍👦`. | Fixed: Unicode cleanup preserves U+200D joiners. | Resolved in CleanPaste Unicode cleanup. |

Additional observations:

- F4 preserves horizontal-rule marker `---`; assess as formatting-noise leakage during target cases.
- F7 preserves real tab separators. Gemini source did not preserve requested indentation for `F7_CODE`, so that indentation gap is provider variability, not CleanPaste attribution.
- F0/F1/F6 canonical outputs match saved manifests exactly.
