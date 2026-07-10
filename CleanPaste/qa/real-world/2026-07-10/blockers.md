# Blockers

Blocked rows remain here even when replaced by a same-profile fallback.

| ID | Surface | Blocker | Evidence | Replacement |
|---|---|---|---|---|
| SRC-CLAUDE | Claude source overlay | Chrome profile reaches Claude sign-in page. Plan forbids account creation or auth expansion. | `https://claude.ai/login?from=logout` observed 2026-07-10. | Gemini provides alternate-provider fixtures. |
| SRC-CHATGPT-LIMIT | ChatGPT source fixture generation | Logged-out guest session reached “Thanks for trying ChatGPT” limit after F0/F1/F6. | Login/sign-up dialog observed after next prompt. | Gemini generated F2-F5/F7. |
| D01 | TextEdit plain-text document | Current agent process can launch TextEdit but cannot create or inspect GUI windows through macOS app automation; Apple Events calls hang. | Two launch/create attempts; TextEdit process present, accessibility window count remains 0. | Pending same-profile desktop fallback or permission change. |
| D02 | TextEdit rich-text document | Same desktop app-control restriction as D01. | Two launch/create attempts; no controllable window. | Pending same-profile desktop fallback or permission change. |
| EVIDENCE-SCREENSHOT | Desktop screenshots | `screencapture` returns black pixels for current GUI session. | 2560x1440 capture inspected; all black. | Use DOM evidence for browser; desktop screenshot requirement remains blocked. |
| W12 | Slack web channel composer | Chrome profile reaches Slack workspace sign-in. Plan forbids auth expansion. | `Find your workspace | Slack` at `workspace-signin`. | Installed Slack adaptation probe attempted; desktop GUI session unavailable. |
| D05-D17,D20 | Remaining native targets | TextEdit/Notes/Pages/VS Code/Xcode became controllable; Mail/Messages/Slack/Discord/Telegram/KakaoTalk/LINE/Notion/Numbers/Keynote/Freeform/Obsidian/Finder still lack stable observable editor windows in current session. | Native app probes vary by Space/window; no cases fabricated for remaining rows. | Same-profile public/editor replacements R01-R19 recorded separately. |
| CHROME-CONTROL | Remaining public replacements | Chrome extension became unresponsive while navigating slow pages and final tab cleanup timed out. | Existing R01-R19 evidence remains on disk; no additional page claimed after timeout. | Resume with lightweight already-open pages or a fresh Chrome session. |
| OS-GUI-SESSION | Desktop app and production target detection | Resolved during continuation: native windows became observable and TextEdit D01/D02 executed through production Command-V. | D01 and D02 each pass 7/7 exact. | Continue native census; retain prior blocker history for audit. |

## Environment note

Chrome-control clipboard is isolated from macOS system pasteboard. Fixture capture therefore records native AI Copy-button MIME payloads inside Chrome, hashes them, then replays exact plain/HTML payloads through `NSPasteboard` so production CleanPaste processes them. Destination-browser cases use corresponding reverse bridge after CleanPaste target adaptation.
