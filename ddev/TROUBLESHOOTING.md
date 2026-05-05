# DDEV Troubleshooting

Issues specific to DDEV containers, ports, and CLI flags. For Drupal-specific
issues that may surface as DDEV symptoms (e.g. config import hangs), see
[`drupal/TROUBLESHOOTING.md`](../drupal/TROUBLESHOOTING.md).

---

## 1.1 DDEV command hangs

### Symptom
A `ddev drush` or `ddev exec` command never returns. The terminal sits with no output.

### Root Cause
Multiple possible causes:
1. **Targeting a stopped project**: If the DDEV project (e.g., `pl-opensocial`) isn't running but you issue `ddev drush` from its directory, the command hangs waiting for the container.
2. **Container unhealthy**: The web or database container is in a degraded state.
3. **PHP fatal error in Drush**: A bootstrap error can cause Drush to hang silently.

### Detection
```bash
# Check if DDEV is running and healthy
ddev describe

# Check container health
docker ps --filter "name=ddev" --format "{{.Names}} {{.Status}}"
```

### Solution
1. **If project isn't running**: Start it with `ddev start`.
2. **If container is unhealthy**: `ddev restart`.
3. **If stuck**: `Ctrl+C`, then check logs with `ddev logs`.

### Prevention
- Always verify DDEV status before running commands: `ddev describe`.
- Never issue DDEV commands against a project you haven't confirmed is running.
- Set a mental 10-second rule: if `ddev drush` shows nothing for 10s, check container health.

---

## 1.2 Duplicate DDEV project port conflicts

*Discovered in session fe852bf3*

### Symptom
Tests get random failures, unexpected responses, or the wrong site content. A test pointed at `pl-opensocial-rework` may unexpectedly see content from `pl-opensocial`.

### Root Cause
Two DDEV projects (e.g., `pl-opensocial` and `pl-opensocial-rework`) running simultaneously can conflict on ports or cause the DDEV router to misdirect traffic, especially if they were configured with similar domain patterns.

### Detection
```bash
# List all running DDEV projects
ddev list

# Check for port conflicts
docker ps --format "{{.Names}} {{.Ports}}" | grep ddev
```

### Solution
Stop the project you're not using:
```bash
cd ~/Sites/pl-opensocial && ddev stop
```

### Prevention
- Before running tests, always stop any DDEV project you're not actively using.
- Never issue `ddev drush` commands from a directory whose DDEV project isn't running — this can hang indefinitely (see §1.1).

---

## 1.3 Nested DDEV project error

*Discovered in session b61df279*

### Symptom
`ddev start` fails with a "nested project" error, or DDEV behaves unpredictably. Configs from a parent directory's `.ddev/` folder interfere with the project's own DDEV configuration.

### Root Cause
An accidental `.ddev/` folder exists in a parent directory (e.g., `~/Sites/.ddev/`). DDEV walks up the directory tree looking for project configuration and finds this stray folder, causing a "nested project" conflict or configuration confusion.

### Detection
```bash
# Check for stray .ddev folders above the project
ls -la ~/Sites/.ddev 2>/dev/null && echo "FOUND — remove this"
ls -la ~/../.ddev 2>/dev/null && echo "FOUND — remove this"
```

### Solution
Remove the stray `.ddev` folder:
```bash
rm -rf ~/Sites/.ddev
```

### Prevention
- Never run `ddev config` from `~/Sites/` directly.
- If you see a "nested project" error, check parent directories for `.ddev/`.

---

## 1.4 DDEV `stop` flag confusion

*Discovered in session b61df279*

### Symptom
Running `ddev stop -y` or `ddev stop -p projectname` fails with unexpected errors. The DDEV project doesn't stop.

### Root Cause
`ddev stop` does not support the `-y` confirmation flag (it doesn't ask for confirmation). The `-p` flag is also not a valid flag for `ddev stop`. These are common assumptions carried over from other CLI tools.

### Correct Usage
```bash
# Stop the current project (from within project directory)
ddev stop

# Stop a specific project by name
ddev stop projectname

# Stop AND remove project data
ddev delete --omit-snapshot -y
```

### Prevention
- Run `ddev stop --help` if unsure about flags.
- For cleanup, use `ddev delete --omit-snapshot -y` which does accept `-y`.

---

## 1.5 DDEV port variability

*Discovered in session b61df279*

### Symptom
Tests fail with "connection refused" or connect to the wrong site. The `playwright.config.ts` has a `baseURL` with a port that doesn't match the actual DDEV project.

### Root Cause
DDEV assigns HTTPS ports that can vary by environment. Common ports include `8443` and `8493`. The port depends on the DDEV router configuration, whether other projects are running, and the host system's port availability.

### Detection
```bash
# Get the actual URL including port
ddev describe | grep -i url
```

### Solution
Update `playwright.config.ts` to match the actual DDEV port:
```typescript
// Check ddev describe output and use the correct port
baseURL: 'https://pl-opensocial-rework.ddev.site:8493'
```

### Prevention
- Always run `ddev describe` before configuring test URLs.
- The BUILD_LOG includes the correct port, but verify it matches your environment.
- Store the URL in an environment variable to avoid hardcoding.
