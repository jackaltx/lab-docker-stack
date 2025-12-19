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

**Git Repository:** <https://github.com/jackaltx/true-lab-docker-stack> (public)

**Branch Workflow:**
- `truenas-dev` - Active development branch
- `test` - Testing/staging (merge from truenas-dev)
- `main` - Production-ready configurations
- Deployment branches may be created later for specific environments

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
- Dashboard: <https://docker.a0a0.org> (Basic Auth protected)
- Binds to: 192.168.40.6:80 and 192.168.40.6:443

### Network Segmentation

**backend_storage** - Infrastructure services (172.20.42.0/24)

- Traefik, MinIO, Arcane, IT-Tools, CyberChef, n8n-dev, n8n (prod)

**backend_media** - Media & application services (172.20.43.0/24)

- Traefik, arr-stack (all components), Jellyfin, Homarr, FreshRSS, Dozzle, 13ft-ladder

**traefik_public** - Traefik internet access

- Bridge network for external connectivity

**n8n_prod_internal** - Private network for n8n-prod PostgreSQL

- Isolated database communication (not accessible from other services)

**Network Creation:**

- Networks are automatically created by Traefik compose on first deployment
- Explicit subnets prevent Docker random allocation
- Other services reference networks as `external: true`
- No manual `docker network create` needed

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

- **HTTPS:** <https://arcane.a0a0.org> (via Traefik)
- **HTTP (direct):** <http://192.168.40.6:30258>

---

## Current Status

✅ **All services operational** (as of 2025-12-05)

**arr-stack:** ✅ Working (fixed 2025-12-03, enhanced 2025-12-05)
- All 12 services deployed and accessible
- VPN routing through Gluetun working
- Added Unpackerr and Recyclarr (2025-12-05)
- Migrated to apps user (PUID=568) for permission alignment
- ⚠️ Note: Readarr metadata search has upstream issues (manual workaround available)

**Other services:** ✅ Working
- Traefik, Jellyfin, Homarr, MinIO, FreshRSS, Dozzle, Arcane, Gitea, etc.

---

## Deployed Projects

### 1. traefik3 - Reverse Proxy & SSL

- **URL:** <https://docker.a0a0.org>
- **Purpose:** Central reverse proxy with automatic SSL
- **Config:** `/mnt/zpool/Docker/Stacks/traefik3`
- **Networks:** Connects to all (backend_storage, backend_media, traefik_public)
- **Deploy First:** Required before any other services

### 2. arr-stack - Media Automation Suite

**Monolithic compose with 12 services:**

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| Gluetun | - | - | VPN gateway (PIA Germany/Frankfurt) for torrent traffic |
| qBittorrent | <https://qbit.a0a0.org> | 8085 | Torrent client (routes via Gluetun VPN) |
| Sonarr | <https://sonarr.a0a0.org> | 8989 | TV show management |
| Radarr | <https://radarr.a0a0.org> | 7878 | Movie management |
| Readarr | <https://readarr.a0a0.org> | 8787 | Book management |
| Lidarr | <https://lidarr.a0a0.org> | 8686 | Music management |
| Prowlarr | <https://prowlarr.a0a0.org> | 9696 | Indexer manager (central tracker config) |
| Bazarr | <https://bazarr.a0a0.org> | 6767 | Subtitle automation |
| Jellyseerr | <https://jellyseerr.a0a0.org> | 5055 | Media request management (Jellyfin-native) |
| FlareSolverr | - | - | Cloudflare bypass for indexers |
| Unpackerr | - | - | Automatic RAR/ZIP extraction from downloads |
| Recyclarr | - | - | Automated quality profile management |

**Media Paths:**

- Movies: `/mnt/zpool/Media/Movies`
- Series: `/mnt/zpool/Media/Series`
- Music: `/mnt/zpool/Media/Music`
- Books: `/mnt/zpool/Media/Books`
- Downloads: `/mnt/zpool/Media/Downloads`

**Deploy Order:** Gluetun must start before qBittorrent

### 3. jellyfin - Media Server

- **URL:** <https://jellyfin.a0a0.org>
- **Port:** 8096
- **Purpose:** Stream movies, TV, music
- **Note:** Hardcoded PUID=568 (different from arr-stack)

### 4. homarr - Dashboard

- **URL:** <https://home.a0a0.org>
- **Port:** 7575
- **Purpose:** Central dashboard for all services
- **Features:** Docker integration for container management

### 5. minio - S3 Object Storage

- **API:** <https://s3-true.a0a0.org> (port 9000)
- **Console:** <https://minio-true.a0a0.org> (port 9001)
- **Purpose:** S3-compatible object storage
- **Storage:** `/mnt/zpool/Docker/Stacks/minio`
- **Default Bucket:** testing

### 6. freshrss - RSS Reader

- **URL:** <https://rss.a0a0.org>
- **Port:** 80
- **Purpose:** Self-hosted RSS feed aggregator

### 7. dozzle - Container Logs

- **URL:** <https://dozzle.a0a0.org>
- **Port:** 8080
- **Purpose:** Real-time Docker container log viewer
- **Access:** Read-only Docker socket

### 8. 13-ft-ladder - Paywall Bypass

- **URL:** <https://ladder.a0a0.org>
- **Port:** 5000
- **Purpose:** Self-hosted paywall bypass for articles

### 9. it-tools - Developer Utilities

- **URL:** <https://it-tools.a0a0.org>
- **Port:** 80
- **Purpose:** Collection of handy IT tools

### 10. cyberchef - Data Transformation

- **URL:** <https://cyberchef.a0a0.org>
- **Purpose:** "Cyber Swiss Army Knife" for data operations

### 11. gitea - Self-Hosted Git Service

- **URL:** <https://gitea.a0a0.org>
- **SSH:** gitea.a0a0.org:2222
- **Ports:** 3000 (web), 2222 (SSH)
- **Purpose:** Lightweight self-hosted Git service with web UI
- **Database:** SQLite3
- **Network:** backend_storage
- **Note:** SSH port on 2222 to avoid conflict with TrueNAS SSH (22)
- **Special:** Data directory must be 568:568 initially, Gitea creates user based on PUID/PGID env vars

### 12. arcane - Docker Management GUI

- **URL:** <https://arcane.a0a0.org>
- **HTTP (direct):** <http://192.168.40.6:30258>
- **Port:** 30258
- **Purpose:** Docker Compose management GUI (similar to Dockge/Portainer)
- **Network:** backend_storage
- **Storage:** `/mnt/zpool/Docker/Stacks/arcane` (SQLite database with stack configs)
- **Features:** Deploy/update stacks, view logs, manage containers
- **Note:** Migrated from TrueNAS Scale app to Docker Compose for consistency

### 13. n8n-dev - Workflow Automation (Development)

- **URL:** <https://n8n-dev.a0a0.org>
- **Port:** 5678
- **Purpose:** Workflow automation for experimentation and testing
- **Database:** SQLite (single container, zero dependencies)
- **Network:** backend_storage
- **Storage:** `/mnt/zpool/Docker/Stacks/n8n-dev/data`
- **UID:** Runs as UID 1000 internally (does NOT respect PUID/PGID)
- **Encryption Key:** `/mnt/zpool/Docker/Secrets/n8n-dev.env`
- **Use for:** Testing workflows, learning n8n, proof of concepts
- **See also:** `n8n-COMPARISON.md` for dev vs prod comparison

### 14. n8n-prod - Workflow Automation (Production)

- **URL:** <https://n8n.a0a0.org>
- **Port:** 5678
- **Purpose:** Production workflow automation (designed for remote VM deployment)
- **Database:** PostgreSQL 16 (dedicated instance)
- **Containers:** 2 (n8n + postgres)
- **Networks:** backend_storage (Traefik access) + n8n_prod_internal (private DB)
- **Storage:**
  - n8n data: `/mnt/zpool/Docker/Stacks/n8n-prod/data`
  - PostgreSQL: `/mnt/zpool/Docker/Stacks/n8n-prod/postgres`
- **UID:** n8n runs as UID 1000, PostgreSQL as UID 999 (both internal)
- **Secrets:** `/mnt/zpool/Docker/Secrets/n8n-prod.env` (DB password + encryption key)
- **Health Check:** PostgreSQL must be ready before n8n starts
- **Backup:** Zero-downtime option via `pg_dump` or full stack backup
- **Use for:** Production workflows, business-critical automation, remote VM deployment
- **Migration:** Workflows can be exported from n8n-dev and imported (credentials must be re-entered)

### 15. security-recon - Passive Reconnaissance Stack

- **Purpose:** VPN-wrapped passive security reconnaissance tools
- **VPN:** Gluetun (PIA) with multi-region rotation capability
- **Network Mode:** All tools share Gluetun's network namespace (VPN routing)
- **Storage:** `/mnt/zpool/Docker/Stacks/security-recon`
- **Results:** `./results/{target}/` organized by scan target

**Tools Included:**
- **nmap** - Service detection and port scanning (`instrumentisto/nmap`)
- **sslscan** - SSL/TLS analysis (via nmap SSL scripts)
- **dnsrecon** - DNS enumeration (`cr0hn/dnsrecon`)
- **curl** - HTTP header inspection (`curlimages/curl`)
- **Kali Linux** - 200+ security tools (`vxcontrol/kali-linux`)
  - whatweb, nikto, subfinder, amass, gobuster, testssl.sh, etc.
  - Fills gaps where standalone Docker images don't exist
  - Pre-configured with automated startup scanning

**Automated Scanning:**
- Container runs `startup-scan.sh` on start
- Executes nmap + whatweb against `SCAN_TARGET` from .env
- Results stream to `./results/${TARGET}/` in real-time
- File ownership automatically fixed for NFS compatibility (PUID/PGID)

**Safety:**
- Configured for passive reconnaissance (no aggressive scanning)
- Test target: `scanme.nmap.org` (scanning allowed)
- VPN region rotation: Edit `.env` SERVER_REGIONS and restart Gluetun
- See `security-recon/README.md` for tool usage and safety guidelines

**Use Cases:**
- Service fingerprinting from multiple geolocations
- Passive OSINT and subdomain discovery
- Web technology detection
- Learning security reconnaissance techniques

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

### Network Creation (Automatic)

Networks are automatically created when Traefik is deployed:
- `backend_storage` (172.20.42.0/24)
- `backend_media` (172.20.43.0/24)
- `traefik_public`

**No manual `docker network create` needed** - Traefik's compose file handles this.

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

- **Web UI:** <https://dozzle.a0a0.org> (all containers)
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
- **n8n** (uses internal UID 1000, does NOT respect PUID/PGID)
- Overseerr (probably ignored)
- Most non-LinuxServer.io images

**Special Case - n8n:**
- Runs as UID 1000 internally (node user)
- Data directories must be owned by 1000:1000
- Does NOT respect PUID/PGID environment variables
- Applies to both n8n-dev and n8n-prod

✅ **TZ works almost everywhere** (most images respect timezone)

**Known Issue:**

- FreshRSS compose file uses `${PUID}` but has no `.env` file → needs to be created

### Naming Conventions

- **Projects:** lowercase-with-hyphens
- **Containers:** lowercase, match service name
- **Domains:** `{service}.a0a0.org`
- **Networks:** `backend_{purpose}`

### Advanced Patterns (Learned in Sprint)

#### PostgreSQL Deployment Pattern (n8n-prod)

**Dedicated PostgreSQL instance per service:**

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: {service}-postgres
    networks:
      - {service}_internal  # Private network
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U {dbuser} -d {dbname}']
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    networks:
      - backend_storage      # Traefik access
      - {service}_internal   # Database access
    depends_on:
      postgres:
        condition: service_healthy  # Wait for DB ready
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres  # Container name on internal network
```

**Why this pattern:**
- Self-contained stack (matches infrastructure philosophy)
- Independent lifecycle management
- Database isolated from other services
- Health checks prevent startup race conditions
- Easy backup/restore (single stack)

#### Health Checks with Depends_on

```yaml
depends_on:
  postgres:
    condition: service_healthy
```

**Ensures:**
- Database ready before application starts
- No connection errors on first boot
- Automatic restart order if postgres crashes

#### Automated Startup Scripts (security-recon)

**Pattern:**
```yaml
services:
  kali:
    command: ["/bin/bash", "/scripts/startup-scan.sh"]
    volumes:
      - ./scripts:/scripts
      - ./results:/results
    environment:
      - SCAN_TARGET=${SCAN_TARGET}
      - PUID=${PUID}
      - PGID=${PGID}
```

**Script responsibilities:**
- Wait for VPN connection (check with `curl ifconfig.me`)
- Run automated tasks (nmap, whatweb, etc.)
- Fix file ownership for NFS compatibility (`chown -R ${PUID}:${PGID}`)
- Keep container running (`tail -f /dev/null`) or exit when done

#### Kali Linux Multi-Tool Container

**Pattern for accessing 200+ security tools:**

```yaml
services:
  kali:
    image: vxcontrol/kali-linux:latest
    network_mode: "service:gluetun"  # Share VPN namespace
    cap_add:
      - NET_ADMIN
      - NET_RAW  # Required for nmap
    volumes:
      - ./results:/results
    command: ["/bin/bash", "/scripts/startup-scan.sh"]
```

**Usage:**
```bash
# Automated via startup script
docker compose up -d

# Manual tool execution
docker compose run --rm kali whatweb -a 1 scanme.nmap.org
docker compose run --rm kali subfinder -d example.com -silent
docker compose run --rm kali nikto -h scanme.nmap.org -Tuning 1
```

**When to use:**
- Standalone Docker images don't exist (whatweb, theharvester)
- Need quick access to many tools without individual containers
- Learning/testing security tools
- Automated scanning workflows

#### Network Namespace Sharing (VPN Routing)

**Pattern from arr-stack and security-recon:**

```yaml
services:
  gluetun:
    # VPN client container
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun

  client:
    network_mode: "service:gluetun"  # Share gluetun's network
    depends_on:
      - gluetun
```

**Effect:**
- Client container has no own network namespace
- All traffic routes through gluetun's VPN
- Cannot expose ports directly (use gluetun's ports)
- Access client via gluetun's IP in network

**Verify routing:**
```bash
docker exec gluetun curl ifconfig.me    # VPN IP
docker exec client curl ifconfig.me     # Same VPN IP (routed!)
```

#### Dual Network Pattern (Public + Private)

**Used by n8n-prod:**

```yaml
networks:
  backend_storage:
    external: true  # Public (Traefik access)
  n8n_prod_internal:
    driver: bridge  # Private (DB only)

services:
  app:
    networks:
      - backend_storage      # Accessible via Traefik
      - n8n_prod_internal    # Can talk to postgres

  postgres:
    networks:
      - n8n_prod_internal    # NOT on backend_storage = isolated
```

**Security benefit:**
- Database not exposed to other services
- Only application can access database
- Traefik cannot reach database directly

#### File Ownership for NFS Mounts

**Problem:** Container writes files as internal UID, NFS mount can't access

**Solution in startup scripts:**

```bash
# Inside container (runs as root)
chown -R ${PUID:-568}:${PGID:-568} /results/*

# Or use find for specific files
find /results -type f -name "*.txt" -exec chown ${PUID}:${PGID} {} \;
```

**Applied in:**
- security-recon startup-scan.sh
- Any service writing to NFS-mounted volumes

---

## Important Notes

### Deployment Dependencies

1. **Deploy Traefik first** - Creates networks (backend_storage, backend_media, traefik_public) and provides routing
2. **arr-stack:** Gluetun must start before qBittorrent (network namespace sharing)
3. **n8n-prod:** PostgreSQL must be healthy before n8n starts (health check dependency)
4. **security-recon:** Gluetun must start before Kali container (network namespace sharing)

### PUID/PGID Variations

- **arr-stack:** Uses PUID=568, PGID=568 (migrated from 1000:1000 on 2025-12-05)
- **jellyfin:** Hardcoded PUID=568 in compose file
- **n8n-dev / n8n-prod:** Runs as UID 1000 internally (does NOT respect PUID/PGID env vars)
- **PostgreSQL:** Runs as UID 999 internally (n8n-prod postgres container)
- **Standard services:** Most use 568:568 (apps user alignment)

### Security Considerations

- All services behind Traefik (no direct port exposure except 80/443)
- Traefik dashboard has Basic Auth
- qBittorrent traffic routes through Gluetun VPN
- Sensitive credentials in .env files (excluded from git)
- Docker socket mounted read-only where possible

### VPN Configuration

- **Provider:** Private Internet Access (PIA)
- **Region:** Germany (Frankfurt) - changed from Italy on 2025-12-05
- **Port Forwarding:** Enabled
- **DNS:** 192.168.101.200 (local network DNS) - changed from 8.8.8.8 on 2025-12-05
- **Routed Services:** qBittorrent only (via `network_mode: service:gluetun`)
- **Firewall:** `FIREWALL_OUTBOUND_SUBNETS=172.20.43.0/24` (matches backend_media subnet defined in Traefik)
- **Configuration:** VPN settings moved from compose.yaml to .env file for easier management

---

## Troubleshooting

### Service Not Accessible

1. Check Traefik dashboard: <https://docker.a0a0.org>
2. Verify service is running: `docker ps | grep {service}`
3. Check network connectivity: `docker network inspect backend_{storage|media}`
4. Review logs: <https://dozzle.a0a0.org> or `docker logs {container}`

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

Automation:
https://n8n-dev.a0a0.org      - n8n Workflow Automation (Dev/Testing)
https://n8n.a0a0.org          - n8n Workflow Automation (Production)

Security:
# security-recon has no web UI - CLI tools only
# Results available in /mnt/zpool/Docker/Stacks/security-recon/results/
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

**Recently Added to arr-stack:**

- ✅ Unpackerr (automatic RAR extraction) - Added 2025-12-05
- ✅ Recyclarr (quality profile automation) - Added 2025-12-05

**Still Missing:**

- Homepage dashboard

**Potential Additions:**

- Ansible playbooks for automated deployment
- Backup automation for configs/data
- Monitoring stack (Prometheus + Grafana)
- Centralized authentication (Authentik/Authelia)
- Git hooks for automatic deployment on push
