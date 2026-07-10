#!/bin/zsh
set -euo pipefail

fixture="${1:?fixture required}"
attempt="${2:-1}"
root="${0:A:h:h}"
fixture_dir="$root/fixtures/$fixture"
case_id="CP-20260710-D03-${fixture}-PRODUCTION-CMDV-A${attempt}"
case_dir="$root/cases/$case_id"
mkdir -p "$case_dir"

swift -e 'import AppKit; import Foundation
let plain = try! String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
let pb = NSPasteboard.general
pb.clearContents()
pb.setString(plain, forType: .string)' "$fixture_dir/raw/plain.txt"
expected_clipboard="$(perl -0pe 's/\n+\z//' "$fixture_dir/expected-preview.txt")"
for _ in {1..25}; do
  [[ "$(pbpaste)" == "$expected_clipboard" ]] && break
  sleep 0.2
done
[[ "$(pbpaste)" == "$expected_clipboard" ]] || { print -u2 'CleanPaste canonical clipboard did not settle'; exit 75; }

osascript <<'APPLESCRIPT'
tell application "Notes"
  reopen
  activate
end tell
delay 0.2
tell application "System Events" to tell process "Notes"
  set frontmost to true
  keystroke "n" using command down
  delay 0.25
  keystroke "v" using command down
end tell
APPLESCRIPT
sleep 0.5

expected_name="$(head -1 "$fixture_dir/expected-preview.txt")"
osascript - "$expected_name" <<'APPLESCRIPT' > "$case_dir/body.html"
on run argv
  tell application "Notes"
    set n to first note whose name starts with item 1 of argv
    return body of n
  end tell
end run
APPLESCRIPT
perl -0pe 'BEGIN { print qq{<meta charset="utf-8">\n} }' "$case_dir/body.html" | textutil -stdin -format html -convert txt -stdout > "$case_dir/actual.txt"
perl -0pi -e 's/\n+\z/\n/' "$case_dir/actual.txt"
perl -0pe 's/\n+\z//' "$fixture_dir/expected-preview.txt" > "$case_dir/expected.txt"
print >> "$case_dir/expected.txt"

if diff -u "$case_dir/expected.txt" "$case_dir/actual.txt" > "$case_dir/diff.txt"; then
  case_status=pass
  score=100
  severity=null
  notes='Exact canonical text match from Notes body HTML.'
else
  case_status=fail
  score=0
  severity='"P1"'
  notes='Notes body text mismatch; inspect diff.'
fi

geometry="$(osascript <<'APPLESCRIPT'
tell application "Notes"
  reopen
  activate
end tell
tell application "System Events" to tell process "Notes"
  set frontmost to true
  set p to position of window 1
  set s to size of window 1
  return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text)
end tell
APPLESCRIPT
)"
screencapture -x -R"$geometry" "$case_dir/after-paste.png"

jq -n --arg id "$case_id" --arg fixture "$fixture" --arg status "$case_status" --arg notes "$notes" --argjson score "$score" --argjson severity "$severity" \
  '{case_id:$id,surface_id:"D03",surface:"Apple Notes note body",fixture_id:$fixture,source_path:"raw provider plain replayed to NSPasteboard",paste_path:"Command-V",status:$status,score:$score,severity:$severity,notes:$notes,executed_at:(now|todateiso8601)}' > "$case_dir/case.json"

osascript - "$expected_name" <<'APPLESCRIPT'
on run argv
  tell application "Notes" to delete (first note whose name starts with item 1 of argv)
end run
APPLESCRIPT

print -- "$case_id $case_status $score"
