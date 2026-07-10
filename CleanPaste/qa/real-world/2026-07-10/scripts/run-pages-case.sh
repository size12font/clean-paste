#!/bin/zsh
set -euo pipefail

fixture="${1:?fixture required}"
attempt="${2:-1}"
root="${0:A:h:h}"
fixture_dir="$root/fixtures/$fixture"
case_id="CP-20260710-D04-${fixture}-PRODUCTION-CMDV-A${attempt}"
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
tell application "Pages"
  activate
  make new document with properties {document template:template "Blank"}
end tell
delay 0.5
tell application "System Events" to tell process "Pages"
  set frontmost to true
  set w to first window whose name starts with "Untitled"
  set p to position of w
  click at {(item 1 of p) + 400, (item 2 of p) + 200}
  keystroke "v" using command down
end tell
APPLESCRIPT
sleep 0.5

osascript -e 'tell application "Pages" to get body text of front document' > "$case_dir/actual.txt"
perl -0pi -e 's/\n+\z/\n/' "$case_dir/actual.txt"
perl -0pe 's/\n+\z//' "$fixture_dir/expected-preview.txt" > "$case_dir/expected.txt"
print >> "$case_dir/expected.txt"

if diff -u "$case_dir/expected.txt" "$case_dir/actual.txt" > "$case_dir/diff.txt"; then
  case_status=pass; score=100; severity=null
  notes='Exact canonical body text match in Pages.'
else
  case_status=fail; score=85; severity='"P2"'
  notes='Pages destination normalization; inspect diff for indentation or tab changes.'
fi

geometry="$(osascript <<'APPLESCRIPT'
tell application "Pages" to activate
tell application "System Events" to tell process "Pages"
  set frontmost to true
  set w to first window whose name starts with "Untitled"
  set p to position of w
  set s to size of w
  return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text)
end tell
APPLESCRIPT
)"
screencapture -x -R"$geometry" "$case_dir/after-paste.png"

jq -n --arg id "$case_id" --arg fixture "$fixture" --arg status "$case_status" --arg notes "$notes" --argjson score "$score" --argjson severity "$severity" \
  '{case_id:$id,surface_id:"D04",surface:"Apple Pages document body",fixture_id:$fixture,source_path:"raw provider plain replayed to NSPasteboard",paste_path:"Command-V",status:$status,score:$score,severity:$severity,notes:$notes,executed_at:(now|todateiso8601)}' > "$case_dir/case.json"

osascript -e 'tell application "Pages" to close front document saving no'
print -- "$case_id $case_status $score"
