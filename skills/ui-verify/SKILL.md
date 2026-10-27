---
name: ui-verify
description: "Verify a web UI in a real, visible browser using the independent read-only ui-verifier agent. Use when the user asks to verify, smoke-test or click through the UI after a change. Usage: /ui-verify <what to check>"
---

# /ui-verify

Run `~/ai/bin/ui-verify` (a separate `claude` process with its own isolated Chrome window, read-only, permissions bypassed behind a guard) and report its verdict. You never edit code and never fix what it finds.

## Procedure

1. If the user gave no argument, ask what to verify. Otherwise use their text.
2. Work from the project root (current worktree). Build a short brief:
   - What changed and what must behave the same (from the user's text, the branch diff, or a handoff file in `tmp/`).
   - Ports and DB: tell the verifier to use the worktree's own (`pnpm worktree:env`), never another checkout's.
   - Login: name the account and say the password is read from an env var or file by reference (for example `ADMIN_PASSWORD` in `apps/backend/.env`), read by the verifier with a shell command (it may see the value) and typed straight into the login form with fill/fill_form; never put it in the report, on the clipboard, or in a file. `ui-verify` masks secret values from the repo's env files in the printed stream.
   - Test data: only records it creates, with a unique prefix (`VKB-` plus a timestamp). Never delete or edit anything else.
   - "Any HTTP 5xx, SQL error in the backend log, or console error is a FAIL."
   - Forbid the clipboard, AppleScript and any local helper server, and forbid writing files into the repo.
3. Keep each run small: at most 3 or 4 flow groups. If the request is bigger, split it into several runs and say so. A huge brief makes the session hit the request-size limit (many screenshots, large snapshots) and ends with no verdict.
4. Tell the user in one or two sentences what will be checked, then run it from the project root in the background, writing output to `$CLAUDE_JOB_DIR/tmp` (or `/tmp` if unset):
   `~/ai/bin/ui-verify "<brief>" > <out> 2>&1; echo "EXIT $?" >> <out>`
   The output is buffered by the tool but the Chrome window is live; tell the user to watch it. They can run the same command with `!` in the prompt to stream the `▶ browser:...` lines.
5. When it finishes, read the output and report: the verdict (exit 0 PASS, 1 FAIL or repo modified, 2 BLOCKED or no verdict), one line per scenario group (PASS/FAIL/NOT VERIFIED), and anything it could not check. Do not claim PASS for groups it marked NOT VERIFIED.
6. On BLOCKED, say why (login failed, no browser tools, request too large) and propose the fix; do not retry blindly.

## Notes

- Exit 1 can also mean the verifier changed repository files. Say so and show the diff stat it printed.
- Screenshots go to files under `/tmp`; the guard blocks inline screenshots and repo writes.
- The same script is the kaboom loop's UI step (`UI_VERIFY=1`, `UI_PATHS`).
