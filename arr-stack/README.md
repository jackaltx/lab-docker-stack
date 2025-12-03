# arr-stack - Media Automation Learning Lab

**Status:** ✅ **WORKING** (as of 2025-12-03)
**Purpose:** Educational exploration of Docker networking and distributed system security

---

## Project Purpose

This arr-stack deployment exists as a **learning laboratory for Docker networking and security concepts**. The arr ecosystem provides an ideal non-trivial distributed system for exploring:

- **Container networking:** Bridge networks, network namespaces, inter-container communication
- **VPN integration:** Traffic routing through containerized VPN (Gluetun)
- **Reverse proxy patterns:** Traefik-based SSL termination and routing
- **Service discovery:** Docker DNS, container hostname resolution
- **Security isolation:** Network segmentation, credential management
- **Distributed system behavior:** Service dependencies, API interactions, state management

**Why arr-stack specifically?**
- Complex multi-service architecture with clear dependencies
- Active development (subject to "quick drift") provides real-world troubleshooting scenarios
- Diverse communication patterns (HTTP APIs, torrent protocols, metadata services)
- "Quasi-ok" societal position makes it useful but low-stakes for experimentation

**This is not a production media automation setup** - it's a technical learning environment.

---

## System Architecture

### Service Stack (10 containers)

```
┌─────────────────────────────────────────────────────────────┐
│                    Traefik (Reverse Proxy)                  │
│              https://*.a0a0.org → SSL termination           │
└─────────────────────────────────────────────────────────────┘
                              ↓
        ┌────────────────────────────────────────────┐
        │         backend_media network               │
        │            (Docker bridge)                  │
        └────────────────────────────────────────────┘
                     ↓              ↓
         ┌───────────────┐    ┌──────────────────┐
         │    Gluetun    │    │   Arr Services   │
         │  (VPN Gateway)│    │                  │
         │  Italy/PIA    │    │ • Sonarr  (TV)   │
         └───────────────┘    │ • Radarr  (Movies)│
                ↓             │ • Lidarr  (Music) │
         ┌──────────────┐    │ • Readarr (Books) │
         │ qBittorrent  │←───│ • Prowlarr (Indexers)│
         │ (shared net) │    │ • Bazarr  (Subs)  │
         └──────────────┘    │ • Jellyseerr (Requests)│
                             │ • FlareSolverr    │
                             └──────────────────┘
```

### Key Networking Patterns

**1. Standard Bridge Network (arr services)**
- All arr services on `backend_media` external bridge network
- Docker DNS resolution (e.g., `http://sonarr:8989`)
- Traefik routes via container hostnames

**2. Shared Network Namespace (qBittorrent + Gluetun)**
- qBittorrent uses `network_mode: service:gluetun`
- Shares Gluetun's network stack (including VPN tunnel)
- Other containers reach qBit via `gluetun:8085`
- Port 8085 exposed on Gluetun for external access

**3. VPN Routing**
- Gluetun establishes OpenVPN tunnel to PIA (Italy)
- qBittorrent traffic routes through VPN
- Port forwarding: Dynamic (currently 30079)
- DNS: Google DNS (8.8.8.8) to avoid Cloudflare blocks

---

## Current Status

### ✅ Working Services

| Service | URL | Internal Port | Status | Notes |
|---------|-----|---------------|--------|-------|
| **Gluetun** | - | - | ✅ Working | VPN: Italy (PIA), Port: 30079 |
| **qBittorrent** | https://qbit.a0a0.org | 8085 | ✅ Working | Peers connecting, VPN verified |
| **Sonarr** | https://sonarr.a0a0.org | 8989 | ✅ Working | TV show automation |
| **Radarr** | https://radarr.a0a0.org | 7878 | ✅ Working | Movie automation |
| **Lidarr** | https://lidarr.a0a0.org | 8686 | ✅ Working | Music automation |
| **Prowlarr** | https://prowlarr.a0a0.org | 9696 | ✅ Working | Indexer management |
| **Bazarr** | https://bazarr.a0a0.org | 6767 | ✅ Working | Subtitle automation |
| **Jellyseerr** | https://jellyseerr.a0a0.org | 5055 | ✅ Working | Request management & media discovery |
| **FlareSolverr** | - | 8191 | ✅ Working | Cloudflare bypass |

### ⚠️ Known Issues

**Readarr (Books):**
- **Status:** Partially working
- **Issue:** Metadata search broken (upstream Readarr issue)
- **Workaround:** Manual grab from Prowlarr → Manual import
- **Root cause:** GoodReads API integration failures
- **Reference:** https://www.reddit.com/r/selfhosted/comments/1ln0sh1/save_readarr_retired_app_after_a_new_maintainer/
- **Impact:** Cannot search for books to add, but indexers and downloads work

---

## Recent Fixes (2025-12-03)

### 1. DNS Configuration
- **Problem:** Cloudflare (1.1.1.1) blocking some indexers
- **Fix:** Changed Gluetun DNS to Google (8.8.8.8)
- **File:** `compose.yaml` - Added `DNS_ADDRESS=8.8.8.8` to Gluetun environment

### 2. Lidarr Port Mismatch
- **Problem:** Traefik routing to wrong port (8787 vs 8686)
- **Fix:** Corrected Traefik label to port 8686
- **Impact:** Lidarr now accessible via https://lidarr.a0a0.org

### 3. VPN Port Forwarding
- **Problem:** qBittorrent not using forwarded port (no peers)
- **Fix:** Configured qBittorrent listening port to 30079
- **Result:** Peers connecting successfully

### 4. FlareSolverr Integration
- **Setup:** Configured for Cloudflare-blocked indexers
- **Tagged indexers:** The Pirate Bay, 1337x, YTS
- **Result:** Indexers working through Cloudflare protection

### 5. Jellyseerr Migration
- **Problem:** Overseerr requires Plex account (not compatible with Jellyfin-only setup)
- **Solution:** Replaced with Jellyseerr (Jellyfin-native fork)
- **Process:** Clean migration - removed old overseerr container/data, deployed fresh jellyseerr
- **Impact:** Request management now fully integrated with Jellyfin

---

## Configuration Details

### Environment Variables

**Location:** `arr-stack/.env`
```env
TZ=America/Chicago
PUID=568    # apps user
PGID=568
DOMAIN=a0a0.org
```

**VPN Credentials:** `/mnt/zpool/Docker/Secrets/arr-stack.env` (not in git)
```env
OPENVPN_USER=<PIA username>
OPENVPN_PASSWORD=<PIA password>
```

### Media Paths

| Type | Container Path | Host Path |
|------|---------------|-----------|
| TV Shows | `/tv` | `/mnt/zpool/Media/Series` |
| Movies | `/movies` | `/mnt/zpool/Media/Movies` |
| Music | `/music` | `/mnt/zpool/Media/Music` |
| Books | `/books` | `/mnt/zpool/Media/Books` |
| Downloads | `/downloads` | `/mnt/zpool/Media/Downloads` |

### Network Details

**backend_media (external bridge network)**
- Created manually: `docker network create backend_media`
- Subnet: 172.20.43.0/24 (example from current deployment)
- Connected services: All arr services, Traefik, Jellyfin, Homarr, etc.

**Container Hostnames (Internal DNS):**
- Gluetun: `gluetun:8085` (qBittorrent WebUI)
- Sonarr: `sonarr:8989`
- Radarr: `radarr:7878`
- Lidarr: `lidarr:8686`
- Readarr: `readarr:8787`
- Prowlarr: `prowlarr:9696`
- Bazarr: `bazarr:6767`
- Jellyseerr: `jellyseerr:5055`
- Jellyfin: `jellyfin:8096` (external service, connected to backend_media)
- FlareSolverr: `flaresolverr:8191`

---

## Usage Workflows

### End-to-End Media Request Flow (with Jellyseerr)

**User-Facing Workflow:**
1. User browses/searches media in **Jellyseerr** (https://jellyseerr.a0a0.org)
2. Jellyseerr shows metadata, ratings, trailers from TMDB/TVDB
3. User clicks "Request" button
4. Jellyseerr sends request to **Sonarr** (TV) or **Radarr** (Movies)
5. User receives notification when media becomes available

**Backend Automation:**
6. **Sonarr/Radarr** receives request, searches via **Prowlarr** (synced indexers)
7. Best result sent to **qBittorrent** (via Gluetun VPN)
8. qBittorrent downloads to `/downloads`
9. Arr app monitors completion, moves to final location (`/tv` or `/movies`)
10. **Bazarr** adds subtitles (if configured)
11. **Jellyfin** detects new media, makes available for streaming
12. **Jellyseerr** marks request as "Available", notifies user

### Jellyseerr Configuration

**Purpose:** User-friendly frontend for media requests, integrated with Jellyfin

**Initial Setup:**
1. First login creates admin account (signs in via Jellyfin)
2. Configure Jellyfin connection:
   - **Internal URL:** `http://jellyfin:8096` (container-to-container)
   - **External URL:** `https://jellyfin.a0a0.org` (user-facing links)
3. Connect Sonarr and Radarr:
   - Use internal hostnames: `http://sonarr:8989`, `http://radarr:7878`
   - Provide API keys from each service
   - Select default quality profiles and root folders

**Key Features:**
- Discover trending/popular media from TMDB/TVDB
- Search across movies and TV shows from single interface
- Request approval workflows (optional)
- User quotas and request limits (optional)
- Email/Discord/Telegram notifications
- Mobile-friendly interface

**Why Jellyseerr vs Overseerr:**
- Jellyseerr is Jellyfin-native fork of Overseerr
- Overseerr designed for Plex, requires Plex Pass for local auth
- Jellyseerr uses Jellyfin authentication directly
- Both support Sonarr/Radarr integration identically

### Basic Media Download Flow (Direct via arr apps)

1. **Add media in arr app** (Sonarr/Radarr/Lidarr) directly
2. Arr app searches via **Prowlarr** (synced indexers)
3. Best result sent to **qBittorrent** (via Gluetun VPN)
4. qBittorrent downloads to `/downloads`
5. Arr app monitors completion, moves to final location
6. **Bazarr** adds subtitles (if configured)
7. **Jellyfin** detects new media, makes available for streaming

### Prowlarr Integration

**Connecting arr apps to Prowlarr:**
- Prowlarr → Settings → Apps → Add Application
- Sync indexers automatically to all arr apps
- Single point of indexer management

**Example: Sonarr connection**
```
Name: Sonarr
Prowlarr Server: http://localhost:9696
Sonarr Server: http://sonarr:8989
API Key: <from Sonarr Settings → General>
Sync Categories: TV (5000-5999)
```

### qBittorrent Download Client Setup

**In each arr app (Sonarr/Radarr/Lidarr):**
```
Settings → Download Clients → Add → qBittorrent

Host: gluetun
Port: 8085
Use SSL: NO
Username: admin
Password: <your qBittorrent password>
Category: tv|movies|music|books (different per app)
```

**Important:** Use hostname `gluetun` not `qbittorrent` (network namespace sharing)

---

## Troubleshooting

### Verify VPN Status

```bash
# Check VPN connection
ssh lavadmin@truenas.a0a0.org
sudo docker logs gluetun | grep "Public IP address"

# Should show Italy IP, not your home IP
sudo docker exec qbittorrent wget -qO- ifconfig.me
```

### Check Container Connectivity

```bash
# Test inter-container communication
sudo docker exec sonarr ping -c 2 prowlarr
sudo docker exec sonarr wget -qO- http://gluetun:8085

# Check network membership
sudo docker network inspect backend_media | grep Name
```

### Traefik Routing Debug

```bash
# View registered routes
curl -s http://192.168.40.6:80/api/http/routers | jq -r '.[] | select(.name | contains("arr")) | .name'

# Check service status
curl -s http://192.168.40.6:80/api/http/services | jq -r '.[] | select(.name | contains("sonarr"))'

# Test direct access (bypass Traefik)
curl -sI http://192.168.40.6:8989  # Sonarr
```

### No Peers in qBittorrent

**Check port configuration:**
1. Verify Gluetun forwarded port: `docker logs gluetun | grep "port forwarded is"`
2. Set in qBittorrent: Tools → Options → Connection → Listening Port
3. Match the port from Gluetun logs (e.g., 30079)
4. Disable UPnP/NAT-PMP
5. Force reannounce torrents

### Indexer Errors (Cloudflare Blocks)

**Configure FlareSolverr:**
1. Prowlarr → Settings → Indexers → FlareSolverr section
2. Add: `http://flaresolverr:8191`
3. Create tag: `cloudflare`
4. Tag blocked indexers with `cloudflare` tag
5. Test indexers - should work now

---

## Deployment

### Initial Setup

```bash
# SSH to TrueNAS
ssh lavadmin@truenas.a0a0.org

# Create network if not exists
sudo docker network create backend_media

# Create data directories
sudo mkdir -p /mnt/zpool/Docker/Stacks/arr-stack/{gluetun,qbittorrent,sonarr,radarr,lidarr,readarr,prowlarr,bazarr,jellyseerr}
sudo chown -R 568:568 /mnt/zpool/Docker/Stacks/arr-stack

# Deploy stack
cd /mnt/zpool/Docker/Projects/arr-stack
sudo docker compose up -d
```

### Update Services

```bash
cd /mnt/zpool/Docker/Projects/arr-stack
sudo docker compose pull
sudo docker compose up -d
```

### View Logs

```bash
# All services
sudo docker compose logs -f

# Specific service
sudo docker compose logs -f sonarr

# Or use Dozzle web UI
# https://dozzle.a0a0.org
```

---

## Security Considerations

### VPN Leak Protection

- qBittorrent shares Gluetun's network namespace (hard isolation)
- Kill switch: If VPN drops, qBittorrent loses connectivity
- Verification: `docker exec qbittorrent curl ifconfig.me` should show VPN IP

### Credential Management

- VPN credentials: `/mnt/zpool/Docker/Secrets/arr-stack.env` (ZFS dataset, not in git)
- API keys: Generated by each arr app, stored in app configs
- qBittorrent password: Auto-generated on first start, view in logs

### Network Isolation

- backend_media: Isolated from host network
- Traefik: Only external entry point (ports 80/443 on 192.168.40.6)
- Internal services: No direct port exposure to host

---

## Learning Exercises

**Things to explore with this stack:**

1. **Network Troubleshooting:**
   - Use `docker network inspect` to understand bridge networking
   - Trace packet flow: Client → Traefik → Container
   - Explore DNS resolution with `docker exec <container> nslookup <other-container>`

2. **VPN Routing:**
   - Compare IPs: `docker exec qbittorrent curl ifconfig.me` vs host IP
   - Monitor traffic: `docker logs gluetun -f`
   - Test kill switch: Stop Gluetun, verify qBittorrent loses connectivity

3. **Service Dependencies:**
   - Stop Prowlarr, observe arr app behavior
   - Stop Gluetun, verify qBittorrent isolation
   - Examine API communication in browser dev tools

4. **Reverse Proxy Patterns:**
   - Study Traefik labels in compose file
   - Monitor routing: `docker logs traefik | grep sonarr`
   - Test SSL: `openssl s_client -connect sonarr.a0a0.org:443`

5. **Container Security:**
   - Run as non-root: Check PUID/PGID in processes
   - Read-only mounts: Observe `/etc/localtime:ro`
   - Capability management: `NET_ADMIN` for Gluetun

---

## Reference Links

**Documentation:**
- [Gluetun Wiki](https://github.com/qdm12/gluetun/wiki)
- [Servarr Wiki](https://wiki.servarr.com/) (Sonarr/Radarr/Lidarr)
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Traefik Docs](https://doc.traefik.io/traefik/)
- [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr)

**Project Context:**
- [Main Repository](https://github.com/jackaltx/lab-docker-stack)
- [SOLTI Project](https://github.com/jackaltx/solti-dev) (AI-assisted development experiment)

---

## File Structure

```
arr-stack/
├── compose.yaml          # Main compose file (10 services)
├── .env                  # Environment variables (PUID, TZ, DOMAIN)
├── README.md             # This file
└── [Container data on TrueNAS]:
    /mnt/zpool/Docker/Stacks/arr-stack/
    ├── gluetun/          # VPN config, port forwarding data
    ├── qbittorrent/      # qBit settings, resume data
    ├── sonarr/data/      # TV show database
    ├── radarr/           # Movie database
    ├── lidarr/config/    # Music database
    ├── readarr/config/   # Book database
    ├── prowlarr/data/    # Indexer configs
    ├── bazarr/           # Subtitle settings
    └── jellyseerr/       # Request system database
```

---

**Last Updated:** 2025-12-03
**Status:** ✅ All services operational (except Readarr metadata search)
**Key Changes:** Jellyseerr replaces Overseerr for Jellyfin-native request management
**Next Steps:** Continue exploring container networking patterns, configure Jellyseerr notifications
