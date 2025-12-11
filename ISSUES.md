# Open Issues - TrueNAS Docker Stack

Issues discovered during operations, to be addressed as time allows.

---

## Open Issues

### #1 - Sonarr ffprobe Missing/Not Working
**Severity:** Medium
**Service:** sonarr
**Discovered:** 2025-12-11
**Status:** Open

**Description:**
Sonarr repeatedly logging errors about missing ffprobe:
```
[Error] DetectSample: Failed to get runtime from the file, make sure ffprobe is available
```

**Impact:**
- Sonarr may have difficulty analyzing media file metadata
- Runtime detection for sample/quality detection may fail
- Could affect automated quality checks

**Possible Causes:**
1. Missing ffprobe binary in LinuxServer.io Sonarr container
2. Corrupted/incomplete media files triggering errors
3. Unsupported media formats

**Next Steps:**
- [ ] Exec into Sonarr container and verify ffprobe installation
- [ ] Check if ffprobe is in PATH
- [ ] Test with known good media file
- [ ] Consider installing ffmpeg package if missing

**References:**
- Status report: [status-reports/2025-12-11-1113.md](status-reports/2025-12-11-1113.md)

---

### #2 - Gluetun IPv6 Route Warning
**Severity:** Low
**Service:** gluetun
**Discovered:** 2025-12-11
**Status:** Open (Informational)

**Description:**
Gluetun VPN container logging IPv6 warning:
```
OpenVPN was configured to add an IPv6 route. However, no IPv6 has been configured
for tun0, therefore the route installation may fail or may not work as expected.
```

**Impact:**
- None currently - IPv4 VPN routing works normally
- Only affects IPv6 traffic if ever enabled

**Next Steps:**
- [ ] Decide if IPv6 support is needed
- [ ] If yes: Configure IPv6 for tun0 interface
- [ ] If no: Suppress warning or ignore

**References:**
- Status report: [status-reports/2025-12-11-1113.md](status-reports/2025-12-11-1113.md)

---

### #3 - sync-env.sh Should Untrack .env Files
**Severity:** Medium
**Component:** sync-env.sh
**Discovered:** 2025-12-11
**Status:** Open

**Description:**
When sync-env.sh adds `**/.env` to .gitignore (protection mode), it doesn't untrack existing .env files that are already in git. This leaves them tracked and showing as modified in git status.

**Impact:**
- Users see .env files as modified even though they should be ignored
- Manual intervention required to untrack files
- Inconsistent behavior - .gitignore added but files still tracked

**Current Behavior:**
```bash
# sync-env.sh -p adds to .gitignore but doesn't untrack
**/.env
# Files remain tracked, show as modified
```

**Expected Behavior:**
```bash
# sync-env.sh should:
1. Add **/.env to .gitignore
2. Run: git rm --cached */**.env (if files are tracked)
3. Commit both changes together
```

**Next Steps:**
- [ ] Review sync-env.sh source code
- [ ] Add git rm --cached logic when -p flag used
- [ ] Test with both tracked and untracked .env files
- [ ] Update documentation

**Workaround:**
```bash
# Manual fix (already applied):
git rm --cached arcane/.env arr-stack/.env filebrowser/.env ...
git add .gitignore
git commit -m "chore: untrack .env files"
```

**References:**
- Commit: 94d258e (manual untrack fix)

---

## Closed Issues

_(None yet)_

---

## Issue Workflow

**Adding New Issues:**
```bash
# Add new issue with next available number
# Include: Severity, Service, Date, Description, Impact, Next Steps
```

**Closing Issues:**
```bash
# Move issue to "Closed Issues" section
# Add resolution date and summary
```

**Priority Levels:**
- **Critical:** Service down, data loss risk
- **High:** Major functionality broken
- **Medium:** Feature impaired, workarounds available
- **Low:** Minor issues, cosmetic, informational
