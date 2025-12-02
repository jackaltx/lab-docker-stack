# Docker Projects Repository - TrueNAS Infrastructure

🌍 **GLOBAL CONFIG LOADED**

## System Overview

**TrueNAS Server:**
- **IP:** 192.168.40.6
- **Hostname:** truenas.a0a0.org
- **SSH Access:** `ssh lavadmin@truenas.a0a0.org`

**Path Mappings:**
```
Local:  /mnt/truenas-projects       → Git repository (compose files)
Remote: /mnt/zpool/Docker/Projects  → Compose files on TrueNAS
Remote: /mnt/zpool/Docker/Stacks    → Persistent container data
Remote: /mnt/zpool/Media            → Media library storage
```

**Repository Type:** Docker Compose configurations managed via Git (similar to Dockge/Arcane)

**Git Repository:** https://github.com/jackaltx/true-docker (private)

---

## Git Workflow & NFS Permissions

**Important:** Local `/mnt/truenas-projects` is an **NFS mount** mapped to apps user (UID 568).

### Permission Issue
- Local mount: NFS share owned by apps user (568)
- `.git/` directory: Owned by root on TrueNAS
- **Result:** Cannot update `.git/config` or create refs locally

### Recommended Git Workflow

**For commits and pushes (use local workstation):**
```bash
cd /mnt/truenas-projects

# Add safe directory (one-time)
git config --global --add safe.directory /mnt/truenas-projects

# Normal git operations
git add .
git commit -m "Your message"
git push  # Uses gh CLI auth automatically

# Note: Ignore local .git/config permission errors - push still succeeds
```

**Why this works:**
- `gh` CLI is authenticated on local workstation
- Push succeeds even if local git config/refs fail to update
- TrueNAS remote has limited tools (no gh CLI)

**Avoid:**
- Git operations directly on TrueNAS via SSH (requires sudo, limited tools)
- Trying to fix .git/ permissions (NFS mount constraints)

### Alternative: Work Directly on TrueNAS
If you need to commit from TrueNAS:
```bash
ssh lavadmin@truenas.a0a0.org
cd /mnt/zpool/Docker/Projects
sudo git add .
sudo git commit -m "message"
# Push fails - no gh CLI or SSH keys configured
# Must push from local workstation
```

---

## Architecture

### Reverse Proxy Setup
All services route through **Traefik v3.2** with:
- Automatic Let's Encrypt SSL certificates (DNS challenge via Linode)
- Dashboard: https://docker.a0a0.org (Basic Auth protected)
- Binds to: 192.168.40.6:80 and 192.168.40.6:443

### Network Segmentation

**backend_storage** - Infrastructure services
- Traefik, MinIO, Arcane, IT-Tools, CyberChef

**backend_media** - Media & application services
- Traefik, arr-stack (all components), Jellyfin, Homarr, FreshRSS, Dozzle, 13ft-ladder

**traefik_public** - Traefik internet access
- Bridge network for external connectivity

**Important:** All networks use `external: true` - must be created manually before deployment.

### Domain Pattern
All services: `{service}.a0a0.org`

### DNS & VLAN Architecture

**Network Setup:**
- TrueNAS has dedicated VLAN with IP: **192.168.40.6**
- DNS managed via **Linode**
- `docker.a0a0.org` → A record → 192.168.40.6
- `*.a0a0.org` → CNAME → docker.a0a0.org
- Traefik binds to 192.168.40.6:80 and :443

**DNS Resolution Flow:**
```
sonarr.a0a0.org → CNAME → docker.a0a0.org → A → 192.168.40.6 → Traefik → Container
```

**Benefits:**
- Single IP for all services
- Wildcard DNS simplifies adding new services
- Network isolation via VLAN
- Automatic SSL via Traefik + Let's Encrypt DNS challenge

---

## Management: Arcane

**What is Arcane:**
- Docker container management tool (similar to Dockge/Portainer)
- Provides GUI for compose file management
- Deployed via Docker Compose (migrated from TrueNAS Scale app)

**Why it's clever:**
- Edit compose files via GUI or Git
- Deploy/update stacks from web interface
- Maintains standard compose file format (not proprietary)
- View logs, manage containers, all from one interface
- Hybrid approach: GUI convenience + compose file portability

**Access:**
- **HTTPS:** https://arcane.a0a0.org (via Traefik)
- **HTTP (direct):** http://192.168.40.6:30258

---

## Current Status

⚠️ **arr-stack is NOT working** (as of 2025-12-01)
- qBittorrent partially accessible
- All other arr services (Sonarr, Radarr, Prowlarr, etc.) not accessible
- VPN/TUN setup with Gluetun causing routing issues
- **See [ARR-STACK-DEBUG.md](ARR-STACK-DEBUG.md) for full debugging context**

✅ **All other services working:**
- Traefik, Jellyfin, Homarr, MinIO, FreshRSS, Dozzle, etc.

---

## Deployed Projects

### 1. traefik3 - Reverse Proxy & SSL
- **URL:** https://docker.a0a0.org
- **Purpose:** Central reverse proxy with automatic SSL
- **Config:** `/mnt/zpool/Docker/Stacks/traefik3`
- **Networks:** Connects to all (backend_storage, backend_media, traefik_public)
- **Deploy First:** Required before any other services

### 2. arr-stack - Media Automation Suite
**Monolithic compose with 10+ services:**

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| Gluetun | - | - | VPN gateway (PIA Italy) for torrent traffic |
| qBittorrent | https://qbit.a0a0.org | 8085 | Torrent client (routes via Gluetun VPN) |
| Sonarr | https://sonarr.a0a0.org | 8989 | TV show management |
| Radarr | https://radarr.a0a0.org | 7878 | Movie management |
| Readarr | https://readarr.a0a0.org | 8787 | Book management |
| Lidarr | https://lidarr.a0a0.org | 8787 | Music management |
| Prowlarr | https://prowlarr.a0a0.org | 9696 | Indexer manager (central tracker config) |
| Bazarr | https://bazarr.a0a0.org | 6767 | Subtitle automation |
| Overseerr | https://overseerr.a0a0.org | 5055 | Media request management |
| FlareSolverr | - | - | Cloudflare bypass for indexers |

**Media Paths:**
- Movies: `/mnt/zpool/Media/Movies`
- Series: `/mnt/zpool/Media/Series`
- Music: `/mnt/zpool/Media/Music`
- Books: `/mnt/zpool/Media/Books`
- Downloads: `/mnt/zpool/Media/Downloads`

**Deploy Order:** Gluetun must start before qBittorrent

### 3. jellyfin - Media Server
- **URL:** https://jellyfin.a0a0.org
- **Port:** 8096
- **Purpose:** Stream movies, TV, music
- **Note:** Hardcoded PUID=568 (different from arr-stack)

### 4. homarr - Dashboard
- **URL:** https://home.a0a0.org
- **Port:** 7575
- **Purpose:** Central dashboard for all services
- **Features:** Docker integration for container management

### 5. minio - S3 Object Storage
- **API:** https://s3-true.a0a0.org (port 9000)
- **Console:** https://minio-true.a0a0.org (port 9001)
- **Purpose:** S3-compatible object storage
- **Storage:** `/mnt/zpool/Docker/Stacks/minio`
- **Default Bucket:** testing

### 6. freshrss - RSS Reader
- **URL:** https://rss.a0a0.org
- **Port:** 80
- **Purpose:** Self-hosted RSS feed aggregator

### 7. dozzle - Container Logs
- **URL:** https://dozzle.a0a0.org
- **Port:** 8080
- **Purpose:** Real-time Docker container log viewer
- **Access:** Read-only Docker socket

### 8. 13-ft-ladder - Paywall Bypass
- **URL:** https://ladder.a0a0.org
- **Port:** 5000
- **Purpose:** Self-hosted paywall bypass for articles

### 9. it-tools - Developer Utilities
- **URL:** https://it-tools.a0a0.org
- **Port:** 80
- **Purpose:** Collection of handy IT tools

### 10. cyberchef - Data Transformation
- **URL:** https://cyberchef.a0a0.org
- **Purpose:** "Cyber Swiss Army Knife" for data operations

### 11. gitea - Self-Hosted Git Service
- **URL:** https://gitea.a0a0.org
- **SSH:** gitea.a0a0.org:2222
- **Ports:** 3000 (web), 2222 (SSH)
- **Purpose:** Lightweight self-hosted Git service with web UI
- **Database:** SQLite3
- **Network:** backend_storage
- **Note:** SSH port on 2222 to avoid conflict with TrueNAS SSH (22)
- **Special:** Data directory must be 568:568 initially, Gitea creates user based on PUID/PGID env vars

### 12. arcane - Docker Management GUI
- **URL:** https://arcane.a0a0.org
- **HTTP (direct):** http://192.168.40.6:30258
- **Port:** 30258
- **Purpose:** Docker Compose management GUI (similar to Dockge/Portainer)
- **Network:** backend_storage
- **Storage:** `/mnt/zpool/Docker/Stacks/arcane` (SQLite database with stack configs)
- **Features:** Deploy/update stacks, view logs, manage containers
- **Note:** Migrated from TrueNAS Scale app to Docker Compose for consistency

---

## Common Operations

**Note:** Docker commands on TrueNAS require `sudo`:
```bash
sudo docker ps
sudo docker network ls
sudo docker compose up -d
```

TrueNAS Scale uses its own user management - add docker group via GUI:
**Credentials → Local Users → Edit lavadmin → Auxiliary Groups → docker**

### Create Required Networks (One-Time Setup)
```bash
ssh lavadmin@truenas.a0a0.org
sudo docker network create backend_storage
sudo docker network create backend_media
```

### Deploy a Stack
```bash
# From TrueNAS
ssh lavadmin@truenas.a0a0.org
cd /mnt/zpool/Docker/Projects/{project}
sudo docker compose up -d
```

### Update a Service
```bash
cd /mnt/zpool/Docker/Projects/{project}
sudo docker compose pull
sudo docker compose up -d
```

### Stop a Stack
```bash
cd /mnt/zpool/Docker/Projects/{project}
sudo docker compose down
```

### View Logs
- **Web UI:** https://dozzle.a0a0.org (all containers)
- **CLI:** `docker compose logs -f {service}`

### Restart Single Service
```bash
cd /mnt/zpool/Docker/Projects/{project}
docker compose restart {service}
```

---

## Common Patterns

### Traefik Labels (Standard Template)
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=backend_{storage|media}"
  - "traefik.http.routers.{service}.rule=Host(`{service}.a0a0.org`)"
  - "traefik.http.routers.{service}.entrypoints=websecure"
  - "traefik.http.routers.{service}.tls.certresolver=letsencrypt"
  - "traefik.http.services.{service}.loadbalancer.server.port={port}"
```

### Volume Mounts (Standard Pattern)
```yaml
volumes:
  # Application config/data
  - /mnt/zpool/Docker/Stacks/{project}:/config

  # Timezone sync
  - /etc/localtime:/etc/localtime:ro

  # Media (for media services)
  - /mnt/zpool/Media/{Movies|Series|Music|Books}:/path/in/container
```

### Port Binding Rules

**Docker Networks:**
All networks are **bridge** networks:
```bash
backend_storage      # Bridge network (local)
backend_media        # Bridge network (local)
traefik3_traefik_public  # Bridge network (local)
ix-arcane_default    # Arcane's network
```

**When to bind ports:**

**1. DO NOT bind web service ports (HTTP/HTTPS)**
Services on backend_storage or backend_media networks:
```yaml
# ❌ WRONG - Don't bind web ports
ports:
  - "3000:3000"

# ✅ CORRECT - Traefik reaches via Docker network
networks:
  - backend_storage
labels:
  - "traefik.http.services.{service}.loadbalancer.server.port=3000"
```
**Why:** Traefik connects directly via bridge network, no host port needed.

**2. DO bind Traefik's gateway ports (hardcoded)**
Traefik compose MUST bind to host:
```yaml
ports:
  - "192.168.40.6:80:8080"   # Dashboard
  - "192.168.40.6:443:443"    # HTTPS entry point
```
**Why:** Traefik is the gateway - host needs to forward external traffic.

**3. DO bind non-HTTP protocol ports**
SSH, custom TCP/UDP services:
```yaml
ports:
  - "192.168.40.6:2222:22"  # Gitea SSH
```
**Why:** Non-HTTP protocols don't route through Traefik.

**Network Inspection:**
```bash
ssh lavadmin@truenas.a0a0.org
sudo docker network ls
sudo docker network inspect backend_storage
```

### Environment Variables

> **📚 IMPORTANT: See [docs/UID-GID-Strategy.md](docs/UID-GID-Strategy.md) for comprehensive UID/GID guidance**

**Standard in all .env files:**
```env
TZ=America/Chicago
PUID=568   # RECOMMENDED: Use apps user (568:568) for new services
PGID=568   # See docs/UID-GID-Strategy.md for rationale
```

**Current Reality (needs migration):**
- Most existing services use PUID=1000 (orphaned UID on TrueNAS)
- Target: Migrate all services to 568:568 (apps user)
- See migration procedure in docs/UID-GID-Strategy.md

**Secrets Location:**
- Each project has `.env` file with service-specific credentials
- `.env.global` exists but currently unused
- **Never commit .env files with actual credentials**

### How .env Files Work

**Docker Compose Auto-Loading:**
- Compose **only** auto-loads `.env` from the **same directory** as `compose.yaml`
- Example: `arr-stack/compose.yaml` → automatically loads `arr-stack/.env`
- `.env.global` is NOT loaded automatically (no compose files reference it)

**Two Variable Injection Mechanisms:**

1. **Compose-Time Substitution** (`${VARIABLE}`)
   ```yaml
   environment:
     - PUID=${PUID}  # Compose reads .env, replaces with actual value
   ```
   - Happens when you run `docker compose up`
   - Variables substituted before containers start
   - If `.env` missing → empty string (can cause issues)

2. **Direct File Loading** (`env_file:`)
   ```yaml
   env_file:
     - .env  # Loads entire file into container as-is
   ```
   - Used by: traefik3, minio
   - No substitution, passes variables directly to container

**When PUID/PGID/TZ Actually Work:**

✅ **Works with LinuxServer.io images:**
- `lscr.io/linuxserver/*` (qBittorrent, Sonarr, Radarr, Prowlarr, Lidarr, Bazarr, FreshRSS)
- `ghcr.io/hotio/*` (Readarr)
- These images read PUID/PGID and drop privileges to that user

❌ **Ignored by official images:**
- Jellyfin official image (uses internal user 568)
- Overseerr (probably ignored)
- Most non-LinuxServer.io images

✅ **TZ works almost everywhere** (most images respect timezone)

**Known Issue:**
- FreshRSS compose file uses `${PUID}` but has no `.env` file → needs to be created

### Naming Conventions
- **Projects:** lowercase-with-hyphens
- **Containers:** lowercase, match service name
- **Domains:** `{service}.a0a0.org`
- **Networks:** `backend_{purpose}`

---

## Important Notes

### Deployment Dependencies
1. **Networks must exist first** (see "Create Required Networks")
2. **Deploy Traefik before other services** (provides routing)
3. **arr-stack:** Gluetun must start before qBittorrent

### PUID/PGID Variations
- **arr-stack:** Uses PUID=1000, PGID=1000
- **jellyfin:** Hardcoded PUID=568 in compose file
- **Mismatch can cause permission issues** when sharing media files

### Security Considerations
- All services behind Traefik (no direct port exposure except 80/443)
- Traefik dashboard has Basic Auth
- qBittorrent traffic routes through Gluetun VPN
- Sensitive credentials in .env files (excluded from git)
- Docker socket mounted read-only where possible

### VPN Configuration
- **Provider:** Private Internet Access (PIA)
- **Region:** Italy
- **Port Forwarding:** Enabled
- **Routed Services:** qBittorrent only (via `network_mode: service:gluetun`)

---

## Troubleshooting

### Service Not Accessible
1. Check Traefik dashboard: https://docker.a0a0.org
2. Verify service is running: `docker ps | grep {service}`
3. Check network connectivity: `docker network inspect backend_{storage|media}`
4. Review logs: https://dozzle.a0a0.org or `docker logs {container}`

### Permission Denied on Media Files
- Verify PUID/PGID matches file ownership
- arr-stack uses 1000:1000, jellyfin uses 568:568
- Check file permissions: `ls -la /mnt/zpool/Media/{path}`

### VPN Not Working (qBittorrent)
```bash
# Check Gluetun status
docker logs gluetun

# Verify VPN connection
docker exec gluetun curl ifconfig.me  # Should show VPN IP

# Test qBittorrent routing
docker exec qbittorrent curl ifconfig.me  # Should match Gluetun IP
```

### SSL Certificate Issues
- Check Traefik logs: `docker logs traefik`
- Verify Linode DNS API token in `.env`
- Ensure DNS records exist for `*.a0a0.org`

### Container Won't Start
1. Check compose file syntax: `docker compose config`
2. Review error logs: `docker compose logs {service}`
3. Verify .env file exists and is readable
4. Check required networks exist: `docker network ls`

---

## Media Workflow

### Download Process
1. Request media via **Overseerr** → sends to Sonarr/Radarr
2. **Sonarr/Radarr** searches indexers via **Prowlarr**
3. Sends download to **qBittorrent** (via VPN)
4. Downloads to `/mnt/zpool/Media/Downloads`
5. **Sonarr/Radarr** moves/renames to final location:
   - Movies → `/mnt/zpool/Media/Movies`
   - Series → `/mnt/zpool/Media/Series`
6. **Bazarr** downloads subtitles automatically
7. **Jellyfin** picks up new media for streaming

---

## Adding New Services

### Template for New Service
1. Create project directory: `/mnt/truenas-projects/{service}/`
2. Create `compose.yaml`:

```yaml
services:
  service-name:
    image: organization/image:tag
    container_name: service-name
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - /mnt/zpool/Docker/Stacks/{service}:/config
      - /etc/localtime:/etc/localtime:ro
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=backend_media"  # or backend_storage
      - "traefik.http.routers.{service}.rule=Host(`{service}.a0a0.org`)"
      - "traefik.http.routers.{service}.entrypoints=websecure"
      - "traefik.http.routers.{service}.tls.certresolver=letsencrypt"
      - "traefik.http.services.{service}.loadbalancer.server.port={port}"
    networks:
      - backend_media  # or backend_storage
    restart: unless-stopped

networks:
  backend_media:
    external: true
```

3. Create `.env`:
```env
PUID=1000
PGID=1000
TZ=America/Chicago
# Add service-specific variables
```

4. Create data directory on TrueNAS:
```bash
ssh lavadmin@truenas.a0a0.org
sudo mkdir -p /mnt/zpool/Docker/Stacks/{service}
sudo chown 1000:1000 /mnt/zpool/Docker/Stacks/{service}
# Or use PUID/PGID from .env: sudo chown {PUID}:{PGID} /mnt/zpool/Docker/Stacks/{service}

# Special case - Gitea: Use 568:568 initially, app creates user from env vars
sudo chown 568:568 /mnt/zpool/Docker/Stacks/gitea
```

5. Deploy:
```bash
ssh lavadmin@truenas.a0a0.org
cd /mnt/zpool/Docker/Projects/{service}
sudo docker compose up -d
```

---

## Quick Reference

### All Service URLs
```
https://docker.a0a0.org      - Traefik Dashboard
https://home.a0a0.org         - Homarr Dashboard
https://dozzle.a0a0.org       - Container Logs

Media Stack:
https://overseerr.a0a0.org    - Request Media
https://jellyfin.a0a0.org     - Watch Media
https://sonarr.a0a0.org       - TV Management
https://radarr.a0a0.org       - Movie Management
https://readarr.a0a0.org      - Book Management
https://lidarr.a0a0.org       - Music Management
https://prowlarr.a0a0.org     - Indexer Management
https://bazarr.a0a0.org       - Subtitle Management
https://qbit.a0a0.org         - Torrent Client

Utilities:
https://s3-true.a0a0.org      - MinIO S3 API
https://minio-true.a0a0.org   - MinIO Console
https://arcane.a0a0.org       - Arcane Docker Management
https://gitea.a0a0.org        - Gitea Git Service
https://rss.a0a0.org          - FreshRSS
https://ladder.a0a0.org       - 13ft Ladder
https://it-tools.a0a0.org     - IT Tools
https://cyberchef.a0a0.org    - CyberChef
```

### SSH Quick Commands
```bash
# Connect to TrueNAS
ssh lavadmin@truenas.a0a0.org

# Navigate to projects
cd /mnt/zpool/Docker/Projects

# View running containers
docker ps

# View all networks
docker network ls

# Check Traefik routing
docker logs traefik | grep -i error
```

---

## Future Enhancements

**Missing from arr-stack (noted in comments):**
- Homepage dashboard
- Unpackerr (automatic RAR extraction)
- Recyclarr (quality profile automation)

**Potential Additions:**
- Ansible playbooks for automated deployment
- Backup automation for configs/data
- Monitoring stack (Prometheus + Grafana)
- Centralized authentication (Authentik/Authelia)
- Git hooks for automatic deployment on push
