# Systems IDE Concept

## Purpose

This project is an experiment in using AI as a **Systems IDE** - not just code, but infrastructure, configuration, and operational knowledge.

## The Real Goal

Build a test harness where AI tooling (Claude Code) can:
- Maintain quality across infrastructure, not just application code
- Learn from documentation patterns to work correctly without constant correction
- Handle real-world messiness (ownership anomalies, special cases, exceptions)
- Verify changes fast enough to enable rapid iteration

## What Makes This Work

### 1. BOM as Ground Truth
- [SOFTWARE-BOM.md](SOFTWARE-BOM.md) - Snapshot of known-good state
- Enables verification: "Does reality match BOM?"
- Documents what's SUPPOSED to be different (anomalies)

### 2. Patterns Documented
- Path interpolation (DOCKER_ROOT, MEDIA_ROOT)
- Hostname variables (SERVICE_HOST)
- Secrets isolation
- UID/GID strategy

### 3. Verification Commands
Quick pass/fail checks:
```bash
# Hardcoded paths violation
grep -r "/mnt/zpool" */compose.yaml

# Hardcoded hostnames violation
grep -r "Host(" */compose.yaml | grep -v '\${.*_HOST}'
```

### 4. Anomalies Documented
AI knows these are CORRECT, not errors:
- FreshRSS: UID/GID 911 (not standard 568)
- Filebrowser: Own internal user system
- Jellyfin: root:apps ownership (needs hardware access)

### 5. Context in Files
Each document teaches the system:
- Portable-Deployment.md → deployment patterns
- SOFTWARE-BOM.md → current state, security surface
- UID-GID-Strategy.md → permission model
- Secrets-Management.md → credential isolation

## The Real Test

**Scenario:** Claude Code loses context, comes back months later.

**Can it:**
- Add new container following established patterns?
- Update BOM correctly?
- Catch hardcoded paths in review?
- Know when to use PUID/PGID vs internal auth?
- Validate deployment without breaking things?
- Understand documented anomalies are intentional?

## Quality Testing Improvements

### Immediate Wins
- ✅ BOM exists as verification baseline
- ✅ Verification commands documented
- ✅ Anomalies explicitly called out
- ✅ Patterns taught through documentation

### Future Enhancements

**1. Automated Validation Script**
```bash
#!/bin/bash
# validate.sh - Run all verification checks

set -e

echo "Checking for hardcoded paths..."
if grep -r "/mnt/zpool" */compose.yaml 2>/dev/null; then
    echo "ERROR: Found hardcoded paths"
    exit 1
fi

echo "Checking for hardcoded hostnames..."
if grep -r "Host(" */compose.yaml | grep -v '\${.*_HOST}'; then
    echo "ERROR: Found hardcoded hostnames"
    exit 1
fi

echo "Verifying BOM matches reality..."
# Compare docker ps output to BOM container list
# Compare docker network ls to BOM networks
# etc.

echo "All checks passed!"
```

**2. BOM Diff Tool**
```bash
# Detect untracked containers
docker ps --format '{{.Names}}' | sort > /tmp/running
grep '^| ' docs/SOFTWARE-BOM.md | awk '{print $2}' | sort > /tmp/documented
diff /tmp/running /tmp/documented
```

**3. Integration Smoke Tests**
```bash
# Can I reach all documented services?
for service in jellyfin sonarr radarr arcane; do
    curl -f -s https://$service.a0a0.org > /dev/null || echo "FAIL: $service"
done
```

**4. Backup Verification**
```bash
# Can I restore from Tier 1 backup?
# Test restoration of:
# - Secrets
# - Traefik acme.json
# - Gitea repos
```

**5. PR Checklist as Executable Tests**
```bash
# When new container added, verify:
# - Present in SOFTWARE-BOM.md
# - No hardcoded paths
# - No hardcoded hostnames
# - Added to sync-env.sh if uses standard variables
# - Stack README created if has special requirements
```

## Success Metrics

**Good AI Systems IDE:**
- AI can return after context loss and maintain quality
- Documentation teaches patterns, not just describes them
- Verification is fast (seconds, not minutes)
- Anomalies are documented, not discovered repeatedly
- Changes can be validated before deployment

**We're Building:**
Not just a Docker stack.
The **training ground for AI infrastructure management.**

## What This Proves

If documentation + verification commands + BOM can enable AI to:
1. Add features correctly
2. Catch violations automatically
3. Understand intentional exceptions
4. Validate before deploying

Then we've demonstrated **AI as Systems IDE is viable.**

---

**Status:** Experimental, early stage. Real-world testing in progress.
