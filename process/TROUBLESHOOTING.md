# Process & Agent Troubleshooting

Cross-cutting issues with orphan processes, signal-handling pitfalls in
cleanup scripts, and AI-agent execution gates. The included master cleanup
script is referenced from several other troubleshooting docs.

---

## 5.1 Orphan Playwright / Node processes

### Symptom
After cancelling a test run, `node` and `chromium` processes remain running. Subsequent test runs may fail with port conflicts or resource exhaustion. The `kill-zombies.sh` script reports these.

### Root Cause
When Playwright is interrupted (SIGTERM/SIGINT), the parent `node` process may die but its child Chromium browser processes survive. Similarly, `npx` may leave behind orphan `node` processes.

### Detection
```bash
# Check for orphan Playwright processes
pgrep -f "playwright" | head
pgrep -f "chromium" | head
```

### Solution
Run the zombie cleanup script:
```bash
bash ~/Sites/pl-opensocial/scripts/kill-zombies.sh
```

Or manually:
```bash
pkill -f "playwright"
pkill -f "chromium"
```

> [!WARNING]
> Bare `pkill -f "playwright"` can kill its own parent shell — see §5.2.

### Prevention
- Run `kill-zombies.sh` **before** every test phase.
- The BUILD_LOG instructs running this script before each phase.
- Always let tests complete rather than cancelling mid-run when possible.

---

## 5.2 `pkill -f "playwright"` self-kill bug

*Discovered in session 85f9e13e*

### Symptom
Running `pkill -f "playwright"` to clean up zombie processes kills its own parent shell. The cleanup command appears to hang or the terminal closes unexpectedly.

### Root Cause
`pkill -f "playwright"` pattern-matches against all processes whose command line contains "playwright" — including the shell running the `pkill` command itself (since the command line contains the string "playwright").

### Detection
- Terminal closes or becomes unresponsive after running `pkill -f "playwright"`.
- The zombie processes may or may not actually get killed.

### Solution
Use a more specific pattern that excludes `pkill` itself:
```bash
# ❌ WRONG — kills itself
pkill -f "playwright"

# ✅ CORRECT — only matches node playwright processes
pkill -f "node.*playwright"
```

### Prevention
- The `kill-zombies.sh` script already uses the corrected pattern.
- Never use bare `pkill -f` with a simple string that could match the command itself.

---

## 5.3 Agent approval gate (false hang)

*Discovered in session d401c580*

### Symptom
A command appears to hang indefinitely — no output, no error, no progress. It looks exactly like a stuck process, but the command never actually started. The terminal just sits there.

### Root Cause
The AI agent submitted the command with `SafeToAutoRun: false`, which means VS Code queues the command for **manual user approval** before executing it. However, the VS Code UI often **does not show an expand button or approval button** — the command is queued invisibly with no way the user can approve it. The command silently never runs, and the agent appears permanently stuck.

This is especially deceptive for obviously safe commands like `ddev export-db` (which just writes a file) or `ddev drush cr` (which clears caches).

### Detection
- The command has been queued but there is **zero output** — not even a partial line.
- There is **no visible approval button or expand button** in the VS Code UI.
- The process is not visible in `ps aux` because it was never launched.
- The only way to break out is to cancel the agent.

### Solution
1. Cancel the agent's current operation.
2. Tell the agent to re-run the command — it will complete in seconds.
3. If exit code 130 appears on retry, that's SIGINT residue from the cancel — just try once more.

### Commands That Should ALWAYS Be Auto-Run
These commands are safe and should never wait for approval:
- `ddev export-db` — writes a backup file
- `ddev drush cr` — clears caches
- `ddev drush status` — read-only status
- `ddev describe` / `ddev list` — read-only info
- `mkdir -p` — creates directories
- `ls`, `cat`, `grep`, `head`, `tail` — read-only
- `cp -r` (for module/config copying) — safe in context
- `npx playwright test` — runs tests

### Prevention
- The agent should mark all non-destructive commands as `SafeToAutoRun: true`.
- Only destructive commands (e.g., `rm -rf`, `ddev delete`, `git push --force`) should require approval.

---

## Master cleanup script

The `scripts/kill-zombies.sh` script handles process cleanup. Run it:

```bash
bash ~/Sites/pl-opensocial/scripts/kill-zombies.sh
```

It checks and kills:
- Orphan Playwright (`node`) processes
- Orphan Chromium browsers
- Orphan Drush processes (host-side)
- Orphan PHP processes (host-side)
- Orphan Composer processes
- Node dev servers
- Orphan curl/wget processes

It also reports DDEV container health status.

**Run this script before every test phase.**
