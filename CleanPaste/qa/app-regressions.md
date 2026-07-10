# App Regressions

Recorded regressions:

- `slack/semantic-lists`: plain list markers pasted as literal characters
  instead of native Slack lists. Fixed by emitting minimal semantic HTML for
  list-bearing canonical content.

Buffer, LinkedIn, Slack, Telegram, Google Docs, Notion, and other applications
are optional spot checks. They are not release-gating matrix columns.

Add an app regression only after canonical plain text visibly differs from the
CleanPaste preview in a reproducible way. Record:

- app and version;
- matching target capability kind;
- source fixture and canonical preview;
- observed pasted output or a non-sensitive digest;
- exact mutation and reproduction steps;
- capability constraint exposed by the failure.

Store the evidence under `qa/regressions/<app>/<case>/`. Add a focused automated
fixture where practical. Do not add an app-specific profile until the
capability violation is proven and the regression survives repetition.
