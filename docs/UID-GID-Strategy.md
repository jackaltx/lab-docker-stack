# UID/GID Strategy for TrueNAS Docker Containers

**Purpose:** Define UID/GID conventions for container deployments on TrueNAS
**Audience:** Humans and AI (especially when generating new compose files)
**Date:** 2025-12-01

---

## Executive Summary

**TL;DR: Use 568:568 (apps user) for all new services unless there's a specific reason not to.**

This matches TrueNAS conventions and provides clean separation between service data and user data.

---

## The UID/GID Choice Problem

When deploying Docker containers on TrueNAS, you must choose what UID/GID the container process runs as. This determines who owns the files on the host filesystem.

**Common choices:**
- **1000:1000** - Arbitrary (common in examples, may not exist on TrueNAS)
- **568:568** - TrueNAS apps user (recommended)
- **3001:950** - lavadmin user (admin convenience, less secure)
- **Custom (5000+)** - Dedicated range (clean but requires sudo access)

---

## TrueNAS User Context

**On truenas.a0a0.org:**

```bash
$ id lavadmin
uid=3001(lavadmin) gid=950(truenas_admin) groups=950(truenas_admin),544(builtin_administrators),999(docker)

$ grep apps /etc/passwd
apps:x:568:568::/nonexistent:/usr/sbin/nologin
```

**Key facts:**
- **apps (568:568)**: TrueNAS service account for app data
- **lavadmin (3001:950)**: Your admin account
- **UID 1000**: Does NOT exist on TrueNAS (common in examples, but orphaned here)

---

## Recommended Strategy: 568:568 (apps user)

### Why 568:568?

1. **TrueNAS Convention**: Apps user is designed for application data
2. **Consistency**: Top-level directories already created as 568:568
3. **Service Account**: Clear separation from personal admin account
4. **No sudo needed**: apps user exists, can be used for backups/maintenance
5. **Future-proof**: If TrueNAS adds app management tools, they'll expect apps ownership

### Implementation

**Standard .env file:**
```env
# Use apps user for all services
PUID=568
PGID=568
TZ=America/Chicago

# Service-specific variables below
```

**In compose.yaml:**
```yaml
services:
  service-name:
    image: organization/image:tag
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    # OR for Gitea-style images:
    environment:
      - USER_UID=${PUID}
      - USER_GID=${PGID}
      - TZ=${TZ}
```

### Result

```bash
/mnt/zpool/Docker/Stacks/redis/
├── data/     568:568 (apps user)
├── config/   568:568 (apps user)
└── logs/     568:568 (apps user)
```

All service data owned by apps, consistent across all services.

---

## Alternative: 3001:950 (lavadmin user)

### Why lavadmin?

**Pros:**
- Direct file access without sudo
- Easy backups/debugging
- Can edit configs directly

**Cons:**
- Service data owned by personal admin account (less clean)
- If lavadmin is deleted, files become orphaned
- Blurs line between admin and service ownership

### When to use

Only if you need **frequent direct file manipulation** and don't want to use sudo.

**Example:**
```env
# Development/testing deployments
PUID=3001
PGID=950
```

---

## Current State: 1000:1000 (Needs Migration)

### Problem

Most current services use **1000:1000** (orphaned UID):

```bash
$ ls -ln /mnt/zpool/Docker/Stacks/gitea/git
drwxr-xr-x 2 1000 1000 2 Nov  6 20:02 lfs
drwxr-xr-x 3 1000 1000 3 Nov  6 20:26 repositories
```

**Issues:**
- No user with UID 1000 exists on TrueNAS
- Requires sudo to access files
- Inconsistent with TrueNAS conventions
- Happened because examples online use 1000 (first user on Ubuntu/Debian)

### Migration Procedure (DO NOT RUN YET - BACKUP FIRST)

**For each service using 1000:1000:**

1. **Backup data** (CRITICAL - test backup restore before proceeding)
   ```bash
   ssh lavadmin@truenas.a0a0.org
   sudo tar czf /backups/gitea-backup-$(date +%Y%m%d).tar.gz \
     /mnt/zpool/Docker/Stacks/gitea/
   ```

2. **Stop the service**
   ```bash
   cd /mnt/zpool/Docker/Projects/gitea
   sudo docker compose down
   ```

3. **Update .env file**
   ```bash
   # Change from:
   PUID=1000
   PGID=1000

   # To:
   PUID=568
   PGID=568
   ```

4. **Fix ownership** (this changes host filesystem)
   ```bash
   sudo chown -R 568:568 /mnt/zpool/Docker/Stacks/gitea/git
   sudo chown -R 568:568 /mnt/zpool/Docker/Stacks/gitea/gitea

   # Verify
   ls -ln /mnt/zpool/Docker/Stacks/gitea/
   ```

5. **Restart service**
   ```bash
   cd /mnt/zpool/Docker/Projects/gitea
   sudo docker compose up -d
   ```

6. **Verify** (check logs, test functionality)
   ```bash
   sudo docker compose logs -f gitea
   # Test: Access service via browser, create test repo, etc.
   ```

7. **Verify file ownership** (container should create new files as 568:568)
   ```bash
   # Create test data inside container
   sudo docker compose exec gitea touch /data/test-file

   # Check ownership on host
   ls -ln /mnt/zpool/Docker/Stacks/gitea/
   # Should show 568:568 for new files
   ```

### Services Requiring Migration

**Known services using 1000:1000:**
- [ ] gitea
- [ ] (check others with: `find /mnt/zpool/Docker/Stacks -user 1000`)

**Before migrating:**
- ✅ Verify backups exist and can be restored
- ✅ Test migration on one service first (smallest/least critical)
- ✅ Document any issues encountered

---

## Image-Specific UID/GID Handling

Different images handle UID/GID differently:

### LinuxServer.io Images (PUID/PGID)

**Images:** lscr.io/linuxserver/*
**Default User:** abc (911:911)
**Env Vars:** PUID, PGID

```yaml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    environment:
      - PUID=568
      - PGID=568
```

**How it works:**
- Entrypoint runs `usermod -o -u $PUID abc` and `groupmod -o -g $PGID abc`
- Modifies existing abc user to your UID/GID
- Works with ANY UID/GID (568, 1000, 3001, etc.)

### Gitea (USER_UID/USER_GID)

**Image:** gitea/gitea
**Default User:** git (1000:1000)
**Env Vars:** USER_UID, USER_GID

```yaml
services:
  gitea:
    image: gitea/gitea:latest
    environment:
      - USER_UID=568
      - USER_GID=568
```

**How it works:**
- Entrypoint uses `sed` to rewrite /etc/passwd and /etc/group
- Changes git user from 1000:1000 to your UID:GID
- Works with ANY UID/GID

### Official Images (No UID/GID Override)

**Images:** redis:alpine, postgres:alpine, etc.
**Default User:** Varies (redis: 999:1000, postgres: 70:70)
**Env Vars:** None (hardcoded)

```yaml
services:
  redis:
    image: redis:7-alpine
    # No PUID/PGID support!
    # Runs as hardcoded UID (999 for redis)
```

**How it works:**
- Uses hardcoded UID from Dockerfile
- Cannot be changed without rebuilding image
- Files will be owned by that hardcoded UID

**Workaround (if needed):**
```yaml
# Use user: directive (requires container runs as that UID)
services:
  redis:
    image: redis:7-alpine
    user: "568:568"
    # May break if image expects specific UID for permissions
```

---

## Checklist for Creating New Services

**When generating compose files, AI should:**

1. **Check if image supports UID/GID override**
   - LinuxServer.io images → Use PUID/PGID
   - Gitea-style images → Use USER_UID/USER_GID
   - Official images → Document that UID is hardcoded

2. **Set standard UID/GID in .env**
   ```env
   PUID=568
   PGID=568
   TZ=America/Chicago
   ```

3. **Create top-level mount point only**
   ```bash
   # Do NOT pre-create internal structure
   sudo mkdir -p /mnt/zpool/Docker/Stacks/service-name
   sudo chown 568:568 /mnt/zpool/Docker/Stacks/service-name
   ```

4. **Let container create internal directories**
   - Container knows what permissions it needs
   - Will create subdirs with appropriate ownership
   - Entrypoint handles UID/GID mapping

5. **Document expected ownership in service README**
   ```markdown
   ## Expected File Ownership

   After first run:
   /mnt/zpool/Docker/Stacks/redis/
   ├── data/     568:568 (created by container)
   ├── config/   568:568 (created by container)
   ```

---

## External Filesystem Mounts

**IMPORTANT:** When mounting external filesystems (NFS, SMB, etc.), UID/GID mapping is critical.

### Problem

External mounts may:
- Have different UID/GID ownership
- Be read-only for certain UIDs
- Not support ownership changes (some NFS configurations)

### Questions to Ask

**When AI generates compose with external mounts:**

1. **What UID owns files on the external mount?**
   ```bash
   ls -ln /mnt/external-share/media
   ```

2. **Can the container UID write to those files?**
   - If media files are 1000:1000, container running as 568 cannot write
   - Options: Change container UID to match, or fix mount ownership

3. **Is the mount read-only?**
   - Media libraries often read-only (Jellyfin, Plex)
   - Downloads directories must be writable (Sonarr, Radarr)

### Example: Media Stack

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin
    volumes:
      - /mnt/zpool/Media/Movies:/movies:ro  # Read-only, UID doesn't matter
      - /mnt/zpool/Media/Series:/tv:ro      # Read-only, UID doesn't matter
      - jellyfin-config:/config             # Writable, uses PUID
```

```yaml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr
    environment:
      - PUID=568
      - PGID=568
    volumes:
      - /mnt/zpool/Media/Series:/tv           # Must match ownership
      - /mnt/zpool/Media/Downloads:/downloads # Must match ownership
```

**If Media is owned by 1000:1000:**
- **Option A:** Change Sonarr to PUID=1000 (matches media ownership)
- **Option B:** Change media ownership to 568:568 (sudo chown -R 568:568 /mnt/zpool/Media)
- **Option C:** Use shared group (add both UIDs to common group)

---

## AI Checklist: Generating New Compose Files

**When asked to create a new service on TrueNAS:**

- [ ] **Check image documentation** for UID/GID override support
- [ ] **Use PUID=568, PGID=568** in .env (apps user)
- [ ] **Document which env vars** to use (PUID/PGID vs USER_UID/USER_GID)
- [ ] **If external mounts**, ask about ownership and access requirements
- [ ] **Don't pre-create internal directories** - let container handle it
- [ ] **Verify image supports UID override** - warn if hardcoded
- [ ] **Add ownership documentation** to service README

**Template .env file:**
```env
# Standard UID/GID (apps user on TrueNAS)
PUID=568
PGID=568
TZ=America/Chicago

# Service-specific variables
SERVICE_PORT=8080
SERVICE_PASSWORD=changeme
```

**Template volume mount:**
```yaml
volumes:
  # Application data (container creates structure as PUID:PGID)
  - /mnt/zpool/Docker/Stacks/service-name:/config

  # Timezone sync
  - /etc/localtime:/etc/localtime:ro

  # External data (check ownership compatibility!)
  # - /mnt/zpool/Media/Movies:/movies:ro  # Read-only example
```

---

## Summary

**Default choice: 568:568 (apps user)**
- Matches TrueNAS conventions
- Service account separation
- Consistent across all services

**When creating new service:**
1. Use 568:568 in .env
2. Let container create internal structure
3. Check external mount ownership
4. Document expected ownership

**Migration from 1000:1000:**
1. BACKUP FIRST
2. Change .env to 568:568
3. sudo chown -R 568:568 data directories
4. Restart and verify

---

## References

- [Podman-User-Namespaces.md](../../solti-containers/docs/Podman-User-Namespaces.md) - Comparison with Podman's namespace mapping
- [LinuxServer.io FAQ](https://docs.linuxserver.io/faq) - PUID/PGID explanation
- TrueNAS Scale apps documentation

---

## Document History

- 2025-12-01: Initial documentation
- Focus: Establish 568:568 as standard, document migration from 1000:1000
