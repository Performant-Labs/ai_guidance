# Claude bridge

A lightweight file-drop protocol that lets a sandboxed AI agent run commands in the host's real shell (with `ddev`, `drush`, `git`, `curl`, Chrome, etc. all available) without handing the agent direct shell access.

The agent writes a request script into `.claude-bridge/req-<id>.sh`; a watcher running on the host picks it up, executes it with the user's privileges, and writes the output and exit code back into the same directory. The agent polls for the response.

## When to use it

Reach for the bridge when the agent needs to do work that requires host-only tooling — typically:

- Run `ddev` / `drush` (e.g. `ddev drush cr`, `ddev drush sqlq`, `ddev drush ev`)
- Hit a local dev URL served by DDEV or a local proxy (e.g. `curl` against `https://local.performantlabs.com/`)
- Launch a headless browser against the local site (e.g. Chrome's `--remote-debugging-port` for DOM probes and screenshots)
- Any command that relies on host-side credentials, environment, or installed applications

If the agent only needs to read or write files in the repo, use the file tools directly — the bridge is overhead you don't need.

## Files

| Path | Role |
|------|------|
| `~/Sites/ai_guidance/agent/claude-bridge.sh` | The watcher. Canonical home — one copy, used across every project. |
| `<repo>/.claude-bridge/` | Per-repo spool directory. Gitignored. Created on first run. |
| `<repo>/.claude-bridge/req-<id>.sh` | Request script from the agent. Deleted after execution. |
| `<repo>/.claude-bridge/res-<id>.out` | Combined stdout + stderr from the request. |
| `<repo>/.claude-bridge/res-<id>.exit` | The request's exit code (single integer, newline-terminated). |

`<id>` is a free-form identifier the agent chooses — typically a short descriptor plus a timestamp, e.g. `cr-logogrid-1776997521`.

**Gitignore requirement:** each repo that uses the bridge must list `.claude-bridge/` in its `.gitignore`. If it's missing, a stray `git add -A` or `git add .` will sweep up pending request files.

## Start the bridge

The watcher is a single script in the canonical ai_guidance location; you do not copy it into each project. In a dedicated terminal, `cd` to the target repo and invoke it:

```bash
cd ~/Projects/<repo>
~/Sites/ai_guidance/agent/claude-bridge.sh
```

Or pass the target explicitly as the first argument:

```bash
~/Sites/ai_guidance/agent/claude-bridge.sh ~/Projects/<repo>
```

You should see a colorized launch banner with the project context:

```
╔══════════════════════════════════════════════════════════════════╗
║  Claude bridge                                                   ║
╚══════════════════════════════════════════════════════════════════╝

  Project        your-project

  watching       /Users/you/Projects/your-project
  spool          /Users/you/Projects/your-project/.claude-bridge
  branch         main (clean)
  origin         in sync
  gh auth        ✓ your-github-login
  pending        none
  watcher        PID 12345, started 2026-04-27 09:15:32

Drops scripts in /Users/you/Projects/your-project/.claude-bridge get
executed on the host with full user privileges (gh, ddev, drush, git,
curl, etc.). Output streams back as res-<id>.out + res-<id>.exit for
the sandboxed agent to poll. Leave this terminal open while collaborating.

⚠  Security: this runs arbitrary shell commands as your user.
   Only run while actively collaborating. Ctrl-C to stop.

Waiting for requests...
```

The banner color-codes each row:

| Field | Colors |
|---|---|
| `Project` | bold magenta — the visual anchor when running multiple watchers |
| `watching` / `spool` | cyan paths |
| `branch` | branch name in bold; `clean` (green) or `dirty` (yellow) |
| `origin` | `in sync` (green), `ahead by N` (blue), `behind by N` (yellow), `diverged` (yellow) |
| `gh auth` | `✓ login` (green) or `✗ not authenticated` (red) |
| `pending` | `none` (gray) or `N queued from prior session` (yellow) |
| `stale res` | shown only if non-zero — `cleared N response file(s)` (yellow) |
| `watcher` | PID + start timestamp (gray) |

The watcher polls `.claude-bridge/` once per second, scrubs any stale `res-*` files from a previous run, and then loops. Safe to Ctrl-C and restart at any time; in-flight requests finish before the loop checks again.

### Multiple watchers (one per project)

You can run several watchers in parallel — one terminal tab per project. The script is fully directory-scoped: each watcher only touches its own `<repo>/.claude-bridge/` and runs commands in its own `cwd`, so two watchers never cross-contaminate.

The bold-magenta `Project` line is the at-a-glance signal of which terminal is for which project. If you want each tab named for its project, the explicit-path form is convenient:

```bash
~/Sites/ai_guidance/agent/claude-bridge.sh ~/Projects/ctrfhub
~/Sites/ai_guidance/agent/claude-bridge.sh ~/Projects/performantlabs.com
```

## Protocol

### Agent side (request)

1. Write an executable shell script to `.claude-bridge/req-<id>.sh`.
2. Poll for `.claude-bridge/res-<id>.exit` (presence means the command finished).
3. Read `res-<id>.out` for combined stdout + stderr, `res-<id>.exit` for the exit code.

Minimal agent-side pattern:

```bash
BRIDGE="$REPO/.claude-bridge"
ID="verify-$(date +%s)"

cat > "$BRIDGE/req-$ID.sh" <<'EOF'
#!/bin/bash
set -e
cd ~/Sites/your-project
ddev drush cr
EOF
chmod +x "$BRIDGE/req-$ID.sh"

for i in {1..30}; do
  if [ -f "$BRIDGE/res-$ID.exit" ]; then
    cat "$BRIDGE/res-$ID.exit"
    cat "$BRIDGE/res-$ID.out"
    break
  fi
  sleep 1
done
```

### Host side (watcher)

For each `req-*.sh` that appears, the watcher:

1. Runs it with `bash "$req" > res-<id>.out 2>&1`
2. Writes the exit code to `res-<id>.exit`
3. Deletes the request file
4. Logs a one-line summary to the terminal (timestamp, id, hint of the first line, exit code, output size)

Commands run with the user's real working directory set to the repo root.

## Timeouts and long-running commands

The watcher itself has no per-request timeout — it waits for the script to finish. The agent side does poll with a bounded loop, though; if the response doesn't arrive in time, the agent gives up but the command keeps running on the host. Choose a polling budget that matches the work (30 s for a cache rebuild, 45 s for a headless Chrome probe, longer for migrations).

For commands that can legitimately take minutes (e.g. `composer install`, `drush migrate:import`), bump the agent's polling loop accordingly rather than fragmenting the work.

## Security

The watcher executes **arbitrary shell commands** that land in `.claude-bridge/` with the running user's privileges. Treat it the same way you'd treat an open SSH session:

- Only run it while you're actively collaborating with the agent.
- Stop it (Ctrl-C) when you step away.
- Don't leave the terminal running unattended.
- Don't point it at a directory anything other than the agent is writing to.

`.claude-bridge/` is gitignored (see the root `.gitignore`), but its contents still live on disk. Clear it periodically if you care about the audit trail, or let the watcher start-scrub handle it on the next launch.

## Typical agent patterns

### Cache rebuild + verification

```bash
cat > "$BRIDGE/req-$ID.sh" <<'EOF'
#!/bin/bash
set -e
cd ~/Sites/your-project
ddev drush cr
curl -sk https://local.your-project.example/ | grep -c "expected-marker"
EOF
```

### Database probe with `drush sqlq`

```bash
cat > "$BRIDGE/req-$ID.sh" <<'EOF'
#!/bin/bash
set -e
cd ~/Sites/your-project
ddev drush sqlq "SELECT COUNT(*) FROM node WHERE type = 'article'"
EOF
```

### Headless Chrome DOM probe (CDP over WebSocket)

Start Chrome with a known debugging port, open the target URL, attach to the tab via `/json`, and evaluate JS through `Runtime.evaluate`. The agent code for this pattern is longer — see the session history where it was used to measure logo bounding boxes after a CSS change.

### Binary output (screenshots, backups)

Write binaries to a stable path that both the host and the agent can read. Pass text descriptors through `res-<id>.out` and copy the binary into the agent's outputs folder if it needs to surface the file to the user.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Agent's poll loop times out but command eventually works | Command ran longer than the agent's budget | Extend the loop, or split the work |
| `res-<id>.exit` shows a non-zero code with empty `res-<id>.out` | Script crashed before producing output (syntax error, missing shebang) | Check the `req-*.sh` content before `chmod +x` |
| Requests accumulate in `.claude-bridge/` and never get processed | Watcher isn't running or is pointed at the wrong directory | Check the launch banner's `watching` line in the dedicated terminal — should match the project. If wrong project (or watcher absent), relaunch: `cd ~/Projects/<repo> && ~/Sites/ai_guidance/agent/claude-bridge.sh` |
| Two watchers running, requests going to the wrong one | Both watchers were launched without `cd` first, both defaulted to `$PWD` of the same shell | Each terminal must `cd` into its own project before launching, or pass the path explicitly: `~/Sites/ai_guidance/agent/claude-bridge.sh ~/Projects/<repo>` |
| Output contains DDEV "stale container" warnings | DDEV project is stopped | `ddev start`, then retry |
| `ddev` commands hang inside the bridge | DDEV is hung, not the bridge | See [`troubleshooting.md`](./troubleshooting.md) section A |

## Design notes

The bridge intentionally stays boring:

- **One direction per file, plain text.** No daemon protocol, no auth tokens, no queue layer. Two filesystem events (write req, read res) are all the synchronization needed.
- **Watcher clears stale responses on start** so a fresh agent session doesn't read results from a previous collaboration.
- **Gitignored spool** keeps the repo clean without needing the agent to remember to clean up.
- **Combined stdout/stderr.** Agents want to see everything in one stream; separating them would only matter if we were piping into another tool.

The tradeoff: the bridge trusts the operator completely. There's no allowlist of commands, no sandboxing, no logging beyond the watcher's terminal echo. That's acceptable because the agent is the one writing the scripts, the operator is the one running the watcher, and both are in the same collaborative session.
