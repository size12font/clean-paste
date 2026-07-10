#!/bin/zsh
set -euo pipefail

fixture="${1:?fixture required}"
root="${0:A:h:h}"
fixture_dir="$root/fixtures/$fixture"
scratch="$root/scratch/D18.txt"
case_id="CP-20260710-D18-${fixture}-PRODUCTION-CMDV-A1"
case_dir="$root/cases/$case_id"
mkdir -p "$case_dir"

print 'QA SCRATCH' > "$scratch"
open -a 'Visual Studio Code' "$scratch"
sleep 0.5

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

geometry="$(osascript <<'APPLESCRIPT'
tell application "Visual Studio Code" to activate
tell application "System Events" to tell process "Code"
  set frontmost to true
  set w to window 1
  set p to position of w
  set s to size of w
  click at {(item 1 of p) + 500, (item 2 of p) + 300}
  keystroke "a" using command down
  keystroke "v" using command down
  keystroke "s" using command down
  delay 0.4
  return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text)
end tell
APPLESCRIPT
)"
screencapture -x -R"$geometry" "$case_dir/after-paste.png"

cp "$scratch" "$case_dir/actual.txt"
perl -0pi -e 's/\n*\z/\n/' "$case_dir/actual.txt"
perl -0pe 's/\n+\z//' "$fixture_dir/expected-preview.txt" > "$case_dir/expected.txt"
print >> "$case_dir/expected.txt"

if diff -u "$case_dir/expected.txt" "$case_dir/actual.txt" > "$case_dir/diff.txt"; then
  case_status=pass; score=100; severity=null
  notes='Exact saved-file match in Visual Studio Code.'
else
  case_status=fail; score=0; severity='"P1"'
  notes='Saved VS Code scratch file differs from canonical text.'
fi

jq -n --arg id "$case_id" --arg fixture "$fixture" --arg status "$case_status" --arg notes "$notes" --argjson score "$score" --argjson severity "$severity" \
  '{case_id:$id,surface_id:"D18",surface:"Visual Studio Code scratch editor",fixture_id:$fixture,source_path:"raw provider plain replayed to NSPasteboard",paste_path:"Command-V",status:$status,score:$score,severity:$severity,notes:$notes,executed_at:(now|todateiso8601)}' > "$case_dir/case.json"
print -- "$case_id $case_status $score"
