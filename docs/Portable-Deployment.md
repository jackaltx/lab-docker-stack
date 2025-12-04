# Portable Deployment Guide

## Overview

All Docker Compose stacks in this repository use **path interpolation** for portability across different machines and environments. Base paths are managed through `.env.global` and synced to individual stack `.env` files.

## Configuration Variables

### Global Variables (.env.global)

```bash
# User and timezone
PUID=568          # TrueNAS app user UID
PGID=568          # TrueNAS app user GID
TZ=America/Chicago

# Networking
DOMAIN=a0a0.org

# Base Paths
DOCKER_ROOT=/mnt/zpool/Docker    # Docker configs, stacks, secrets
MEDIA_ROOT=/mnt/zpool/Media      # Media files (movies, music, etc.)
```

### Path Interpolation in Compose Files

All `compose.yaml` files use environment variable interpolation:

```yaml
volumes:
  - ${DOCKER_ROOT}/Stacks/app:/config
  - ${MEDIA_ROOT}/Movies:/movies
```

## Deployment Workflow

### New Machine Setup

1. **Clone repository:**
   ```bash
   git clone https://github.com/jackaltx/lab-docker-stack.git
   cd lab-docker-stack
   ```

2. **Edit global configuration:**
   ```bash
   vim .env.global
   ```
   Update paths for your environment:
   ```bash
   DOCKER_ROOT=/your/docker/path
   MEDIA_ROOT=/your/media/path
   DOMAIN=yourdomain.com
   ```

3. **Sync to all stacks:**
   ```bash
   ./sync-env.sh
   ```
   This propagates `.env.global` values to all stack `.env` files.

4. **Create directory structure:**
   ```bash
   # For arr-stack
   cd arr-stack
   ./prepare-arr-stack.sh

   # Or manually create base directories
   mkdir -p $DOCKER_ROOT/{Projects,Stacks,Secrets}
   mkdir -p $MEDIA_ROOT/{Movies,Series,Music,Books,Downloads}
   ```

5. **Deploy stacks:**
   Use Arcane GUI or docker compose:
   ```bash
   docker compose -f traefik3/compose.yaml up -d
   docker compose -f arcane/compose.yaml up -d
   ```

## Stacks Using Path Interpolation

### All Stacks (8)
- **freshrss** - DOCKER_ROOT
- **traefik3** - DOCKER_ROOT
- **arcane** - DOCKER_ROOT
- **gitea** - DOCKER_ROOT
- **homarr** - DOCKER_ROOT
- **jellyfin** - DOCKER_ROOT, MEDIA_ROOT
- **minio** - DOCKER_ROOT
- **arr-stack** - DOCKER_ROOT, MEDIA_ROOT

### Stacks Without Hardcoded Paths (4)
These don't need path variables:
- **13-ft-ladder**
- **cyberchef**
- **dozzle**
- **it-tools**

## Directory Structure

### DOCKER_ROOT Layout
```
${DOCKER_ROOT}/
├── Projects/           # Arcane project workspace
├── Stacks/            # Per-stack config directories
│   ├── traefik/
│   │   ├── traefik.yml
│   │   ├── acme/
│   │   └── access.log
│   ├── arcane/
│   ├── arr-stack/
│   │   ├── gluetun/
│   │   ├── qbittorrent/
│   │   ├── sonarr/
│   │   └── ...
│   └── ...
└── Secrets/           # Secrets .env files
    ├── traefik.env    # LINODE_TOKEN
    ├── arcane.env     # ENCRYPTION_KEY, JWT_SECRET
    ├── arr-stack.env  # VPN credentials
    └── ...
```

### MEDIA_ROOT Layout
```
${MEDIA_ROOT}/
├── Downloads/         # Torrent downloads
├── Movies/           # Radarr managed
├── Series/           # Sonarr managed
├── Music/            # Lidarr managed
├── Books/            # Readarr managed
└── Music-Lessons/    # Custom category
```

## Environment Variable Sync

### sync-env.sh

Syncs variables from `.env.global` to stack `.env` files:

**Behavior:**
- Only updates variables that **already exist** in target `.env`
- Doesn't add new variables
- Preserves stack-specific variables (e.g., `USER_PASSWD` in traefik3)

**Example:**
```bash
./sync-env.sh
```

**Output:**
```
Processing: freshrss/.env
  - Updating PUID=568
  - Updating PGID=568
  - Updating TZ=America/Chicago
  - Updating DOMAIN=a0a0.org
  - Updating DOCKER_ROOT=/mnt/zpool/Docker

Sync complete!
```

## Migration Example

### From TrueNAS to Debian VPS

**TrueNAS paths:**
```bash
DOCKER_ROOT=/mnt/zpool/Docker
MEDIA_ROOT=/mnt/zpool/Media
```

**Debian VPS paths:**
```bash
DOCKER_ROOT=/srv/docker
MEDIA_ROOT=/mnt/media
```

**Migration steps:**
1. Edit `.env.global` on VPS
2. Run `./sync-env.sh`
3. Verify with: `grep -r "DOCKER_ROOT" */\.env`
4. Deploy stacks

No compose file edits required!

## Bootstrap Script (Future)

Planned `bootstrap.sh` script will automate:
1. Prompt for base paths
2. Update `.env.global`
3. Run `sync-env.sh`
4. Create directory structure
5. Generate secrets
6. Start Traefik + Arcane
7. Display Arcane URL for further deployment

## AI Assistant Notes

### For Claude Code

When working with this repository:

1. **Never hardcode paths** - Always use `${DOCKER_ROOT}` or `${MEDIA_ROOT}`
2. **Update .env.global first** - Then run sync-env.sh
3. **Add new stacks to sync-env.sh** - Add to TARGETS array
4. **Test interpolation** - Verify with `docker compose config`

### Path Variable Rules

- **DOCKER_ROOT** - For all application config, state, secrets
- **MEDIA_ROOT** - For media files only (movies, music, books, etc.)
- **Never use** - `/mnt/zpool`, `/opt/Docker`, or any absolute paths

### Verification Commands

```bash
# Check for hardcoded paths
grep -r "/mnt/zpool" */compose.yaml

# Verify interpolation works
cd traefik3 && docker compose config | grep -A5 volumes

# Test sync
./sync-env.sh
```

## Troubleshooting

### Variables Not Interpolating

**Problem:** Paths show as `${DOCKER_ROOT}` instead of actual values

**Solutions:**
1. Check `.env` file exists in same directory as `compose.yaml`
2. Verify variable is defined: `grep DOCKER_ROOT .env`
3. Don't use `sh` - Use `bash` or `./sync-env.sh`

### Permission Denied Errors

**Problem:** Containers can't write to mounted volumes

**Solutions:**
1. Check ownership: `ls -l $DOCKER_ROOT/Stacks/`
2. Fix with: `chown -R 568:568 $DOCKER_ROOT/Stacks/`
3. See [UID-GID-Strategy.md](UID-GID-Strategy.md)

### Secrets Not Found

**Problem:** `env_file` path not found

**Solutions:**
1. Check: `ls $DOCKER_ROOT/Secrets/`
2. Create missing secrets files (see [Secrets-Management.md](Secrets-Management.md))
3. Verify interpolation: `docker compose config`

## Related Documentation

- [Secrets-Management.md](Secrets-Management.md) - Secrets storage strategy
- [UID-GID-Strategy.md](UID-GID-Strategy.md) - Permission management
- [CLAUDE.md](../CLAUDE.md) - Complete system documentation
