# Git Troubleshooting

Issues with `git` operations as run by AI agents — pager hangs, multi-repo
loops, and the symlink-based sharing model used to distribute this guidance.

---

## 3.1 Symlink synchronization (missing files appear)

*Discovered in session cfb93ae7. Updated when the project moved from git
subtrees to symlinks for sharing the `ai_guidance` directory.*

### Symptom
Files you recently created or edited inside the `ai_guidance` source repository
are missing from a host project's `docs/ai_guidance/` directory, even though
both should be reading from the same place.

### Root Cause
The `ai_guidance` directory inside each host project is a **symbolic link** to
the canonical source repository (typically `~/Projects/ai_guidance`). If the
symlink is broken — pointing at the wrong path, was committed as a regular file
on a different OS, or was replaced by a real directory — the host sees a stale
or empty version of the docs.

This replaces an earlier git-subtree workflow that pushed/pulled snapshots
between repos. With symlinks the contents are always live, so any edit in the
source repo is instantly visible everywhere.

### Detection
Inside the host project:

```bash
# Verify the path is a symlink and where it points
ls -la docs/ai_guidance
# Expected output starts with `lrwxr-xr-x` and shows the target after `->`

# Verify the target exists and contains expected files
ls -la "$(readlink docs/ai_guidance)"
```

If `ls` shows a normal directory (`drwxr-xr-x`) instead of a symlink, somebody
checked the actual files into the host repo by mistake.

### Solution
Recreate the symlink:

```bash
# From the host project's root
rm -rf docs/ai_guidance
ln -s ~/Projects/ai_guidance docs/ai_guidance
```

Verify with `ls -la docs/ai_guidance` — first character should be `l`.

If the host repo had committed a real `docs/ai_guidance/` directory by accident,
add it to the host's `.gitignore` after re-linking:

```
# .gitignore
docs/ai_guidance
```

### Prevention
- **Never commit the `docs/ai_guidance` symlink target itself.** Add the path to
  `.gitignore` in every host project.
- When onboarding a new machine or contributor, the symlink is recreated by
  running the one-line setup command (see `setup/README.md` in the source repo).
- Don't `cp -r` the contents of `ai_guidance` into a host project. Always link.

---

## 3.2 AI agent hung on `git` commands (Git pager)

*Discovered in session cfb93ae7*

### Symptom
An AI agent attempts to run a terminal command like `git log`, `git show`, or `git diff` and appears to hang indefinitely. It never processes the output and requires you to manually intervene and cancel the running process.

### Root Cause
By default, Git pipes any output stream exceeding one screen height through a terminal pager (typically `less`). The pager inherently waits for a human user to physically press the `q` key to gracefully exit. Because the AI is executing non-interactively, it cannot send the `q` keystroke, causing the agent to hang permanently.

### Detection
- The agent executes a Git inspection command.
- The terminal execution timer ticks indefinitely (e.g. 1m+) without resolving.
- `ps aux | grep less` may show an abandoned pager instance process.

### Solution
1. Cancel the agent's hung process.
2. Explicitly instruct the agent to run the command with the `--no-pager` flag.

### Prevention
AIs must **always explicitly disable the pager** when running stream commands in this environment:

```bash
# ❌ WRONG — hangs the AI indefinitely inside 'less'
git log -1

# ✅ CORRECT — safely bypasses the pager and returns immediately
git --no-pager log -1
```

---

## 3.3 Multi-repo scripts appearing stuck (execution duration)

*Discovered in session cfb93ae7*

### Symptom
An AI agent executes a bash `for` loop that iterates over multiple repositories
(e.g., running `git fetch` across 7 local projects). The command execution
timer ticks for 30–45 seconds, making the system look completely frozen,
identical to a `git log` pager hang (§3.2).

### Root Cause
Operations that hit network borders sequentially — like initiating distinct SSH
handshakes to `git@github.com` via `git fetch` — take approximately 4–6 seconds
per repository. A 7-repository loop legitimately takes ~35 seconds to physically
complete. The terminal is perfectly healthy; it is simply blocking while
completing the heavy I/O operations.

### Detection
- Inspect the exact command string. If it contains a
  `for repo in "${REPOS[@]}"; do ... git fetch ... done` loop, it is
  systematically iterating.
- Wait at least 60 seconds before assuming the loop is structurally broken.

### Solution
Allow the agent's command to peacefully finish its network queue. If you
accidentally cancel a long-running loop, simply re-run it.

### Prevention
- Add a leading `echo "starting <repo>"` inside any multi-repo loop so the
  terminal shows progress instead of going silent.
- Where it makes sense, parallelize with `xargs -P` or background `&` plus
  `wait` so total duration is gated by the slowest single fetch, not the sum.
