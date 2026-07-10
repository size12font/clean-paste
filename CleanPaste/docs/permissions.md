# Permissions

CleanPaste needs Accessibility permission only to send automatic Command-V.
**Clean clipboard now** works without it.

When permission is denied:

- clipboard normalization still completes;
- no synthetic paste event is sent;
- the clean preview remains visible;
- status says to press Command-V manually.
- the macOS permission prompt appears at most once per app session.

Enable permission in **System Settings > Privacy & Security > Accessibility**.

Launch at login is separate. Enabling the toggle registers the app with macOS;
the preference is persisted only after registration succeeds.
