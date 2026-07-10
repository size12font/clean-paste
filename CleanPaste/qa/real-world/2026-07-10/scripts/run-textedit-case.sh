#!/bin/zsh
set -euo pipefail

if (( $# < 3 || $# > 4 )); then
  print -u2 'usage: run-textedit-case.sh <D01|D02> <fixture> <plain|rich> [attempt]'
  exit 64
fi

surface="$1"
fixture="$2"
mode="$3"
attempt="${4:-1}"
root="${0:A:h:h}"
fixture_dir="$root/fixtures/$fixture"
case_id="CP-20260710-${surface}-${fixture}-PRODUCTION-CMDV-A${attempt}"
case_dir="$root/cases/$case_id"

[[ -f "$fixture_dir/raw/plain.txt" ]] || { print -u2 "missing fixture: $fixture"; exit 66; }
mkdir -p "$case_dir"

html_path="$fixture_dir/raw/source.html"
if [[ -f "$html_path" ]]; then
  swift -e 'import AppKit; import Foundation
let plain = try! String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
let html = try! String(contentsOfFile: CommandLine.arguments[2], encoding: .utf8)
let pb = NSPasteboard.general
pb.clearContents()
pb.setString(plain, forType: .string)
pb.setString(html, forType: .html)' "$fixture_dir/raw/plain.txt" "$html_path"
else
  swift -e 'import AppKit; import Foundation
let plain = try! String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
let pb = NSPasteboard.general
pb.clearContents()
pb.setString(plain, forType: .string)' "$fixture_dir/raw/plain.txt"
fi

# Production monitor polls every 0.2 seconds; wait for the frozen canonical value.
expected_clipboard="$(perl -0pe 's/\n+\z//' "$fixture_dir/expected-preview.txt")"
for _ in {1..25}; do
  [[ "$(pbpaste)" == "$expected_clipboard" ]] && break
  sleep 0.2
done
[[ "$(pbpaste)" == "$expected_clipboard" ]] || { print -u2 'CleanPaste canonical clipboard did not settle'; exit 75; }

actual="$(osascript - "$mode" <<'APPLESCRIPT'
on run argv
  set targetMode to item 1 of argv
  tell application "TextEdit"
    activate
    make new document
  end tell
  delay 0.25
  tell application "System Events"
    tell process "TextEdit"
      set frontmost to true
      tell menu bar 1
        tell menu bar item "Format"
          tell menu "Format"
            if targetMode is "plain" then
              if exists menu item "Make Plain Text" then click menu item "Make Plain Text"
            else
              if exists menu item "Make Rich Text" then click menu item "Make Rich Text"
            end if
          end tell
        end tell
      end tell
      delay 0.2
      keystroke "v" using command down
    end tell
  end tell
  delay 0.35
  tell application "TextEdit" to return text of front document
end run
APPLESCRIPT
)"

print -r -- "$actual" > "$case_dir/actual.txt"
perl -0pe 's/\n+\z//' "$fixture_dir/expected-preview.txt" > "$case_dir/expected.txt"
print >> "$case_dir/expected.txt"

if diff -u "$case_dir/expected.txt" "$case_dir/actual.txt" > "$case_dir/diff.txt"; then
  case_status=pass
  score=100
  severity=null
  notes='Exact canonical text match from production CleanPaste clipboard path.'
else
  case_status=fail
  score=0
  severity='"P1"'
  notes='Text mismatch; inspect diff and reproduce before attribution.'
fi

geometry="$(osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "TextEdit"
    set p to position of window 1
    set s to size of window 1
    return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text)
  end tell
end tell
APPLESCRIPT
)"
screencapture -x -R"$geometry" "$case_dir/after-paste.png"

jq -n \
  --arg case_id "$case_id" \
  --arg surface_id "$surface" \
  --arg fixture_id "$fixture" \
  --arg mode "$mode" \
  --arg status "$case_status" \
  --arg notes "$notes" \
  --argjson score "$score" \
  --argjson severity "$severity" \
  '{case_id:$case_id,surface_id:$surface_id,surface:("TextEdit " + $mode + " document"),fixture_id:$fixture_id,source_path:"raw provider payload replayed to NSPasteboard",paste_path:"Command-V",status:$status,score:$score,severity:$severity,notes:$notes,executed_at:(now|todateiso8601)}' \
  > "$case_dir/case.json"

osascript <<'APPLESCRIPT'
tell application "TextEdit" to if (count of documents) > 0 then close front document saving no
APPLESCRIPT

print -- "$case_id $case_status $score"
