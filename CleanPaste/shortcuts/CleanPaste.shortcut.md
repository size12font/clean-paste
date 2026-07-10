# CleanPaste Shortcut Blueprint

Build manually in Shortcuts:

1. `Get Clipboard`
2. `Replace Text` regex `[\u00A0\u202F\u2007\u2009\u200A]` -> space
3. `Replace Text` regex `[\u200B\u200C\u200D\u2060\uFEFF]` -> empty
4. Remove code-fence lines with `Replace Text`:

   ~~~regex
   (?m)^\s*(?:`{3}|~{3}).*$
   ~~~

5. `Replace Text` regex `\*\*([^*\n]+)\*\*` -> `$1`
6. `Replace Text` regex `` `([^`\n]+)` `` -> `$1`
7. `Replace Text` regex `(?m)[ \t]+$` -> empty
8. `Replace Text` regex `\n{3,}` -> `\n\n`
9. `Copy to Clipboard`

Spot-check against top five fixtures before treating mobile output as reliable.

Use `swift run --package-path CleanPaste CleanPasteShortcutQA` to verify the
same replacement chain against the checked-in mobile-safe fixtures. Device
trigger wiring remains manual.
