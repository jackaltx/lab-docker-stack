# arr-stack Debugging Context

**Status:** NOT WORKING (except qBittorrent partially accessible)
**Date:** 2025-12-01
**Priority:** High - Core media automation stack is down

---

## Current Problem Summary

### What Works ✅
- **qBittorrent:** Accessible at https://qbit.a0a0.org
- VPN tunnel is "kinda/sorta" working (Gluetun container running)

### What Doesn't Work ❌
- **All other arr services inaccessible:**
  - Sonarr (https://sonarr.a0a0.org)
  - Radarr (https://radarr.a0a0.org)
  - Prowlarr (https://prowlarr.a0a0.org)
  - Readarr (https://readarr.a0a0.org)
  - Lidarr (https://lidarr.a0a0.org)
  - Bazarr (https://bazarr.a0a0.org)
  - Overseerr (https://overseerr.a0a0.org)

**Key Issue:** VPN/TUN networking setup with Gluetun is causing routing problems for services on the `backend_media` network.

---

## Network Architecture

### DNS & VLAN Setup

**TrueNAS Network:**
- **VLAN IP:** 192.168.40.6 (dedicated to Docker host)
- **Hostname:** truenas.a0a0.org
- **DNS Provider:** Linode

**DNS Records (Linode):**
```
docker.a0a0.org       A      192.168.40.6
*.a0a0.org            CNAME  docker.a0a0.org

Resolves to:
sonarr.a0a0.org    →  CNAME  →  docker.a0a0.org  →  192.168.40.6
radarr.a0a0.org    →  CNAME  →  docker.a0a0.org  →  192.168.40.6
qbit.a0a0.org      →  CNAME  →  docker.a0a0.org  →  192.168.40.6
[etc...]
```

**Traefik Entry Point:**
- Binds to: `192.168.40.6:80` and `192.168.40.6:443`
- SSL: Let's Encrypt via DNS challenge (Linode API)
- Dashboard: https://docker.a0a0.org (working)

### Docker Networks

**backend_media** (external network)
- All arr-stack services connect to this
- Traefik also connects (acts as gateway)
- Network mode: bridge

**Special Case: qBittorrent**
- Uses `network_mode: service:gluetun`
- Shares Gluetun's network namespace
- Traffic routed through VPN tunnel

---

## arr-stack Compose Structure

### Service Dependencies

```
Gluetun (VPN Gateway)
    ↓ (network_mode: service:gluetun)
qBittorrent ← Works ✅

Prowlarr ─┬─→ Sonarr ─┐
          ├─→ Radarr ─┤
          ├─→ Readarr ├─→ qBittorrent
          └─→ Lidarr ─┘
              ↓
          Bazarr
              ↓
          Overseerr

All ← backend_media network ← NOT WORKING ❌
```

### VPN Configuration (Gluetun)

**Location:** `arr-stack/compose.yaml` - gluetun service

```yaml
gluetun:
  image: qmcgaw/gluetun
  container_name: gluetun
  cap_add:
    - NET_ADMIN    # Required for TUN/TAP device
  devices:
    - /dev/net/tun:/dev/net/tun
  ports:
    - 8085:8085    # qBittorrent WebUI
    - 6881:6881    # qBittorrent TCP
    - 6881:6881/udp
  environment:
    - VPN_SERVICE_PROVIDER=private internet access
    - OPENVPN_USER=${OPENVPN_USER}
    - OPENVPN_PASSWORD=${OPENVPN_PASSWORD}
    - SERVER_COUNTRIES=Italy
    - VPN_PORT_FORWARDING=on
    - TZ=${TZ}
  volumes:
    - /mnt/zpool/Docker/Stacks/arr-stack/gluetun:/gluetun
```

**Environment Variables (.env):**
```env
TZ=America/Chicago
PUID=1000
PGID=1000
OPENVPN_USER=<your_pia_username>
OPENVPN_PASSWORD=<your_pia_password>
```

**Note:** Actual credentials stored in `/mnt/zpool/Docker/Secrets/arr-stack.env` (not in git)

### qBittorrent Configuration

```yaml
qbittorrent:
  image: lscr.io/linuxserver/qbittorrent
  container_name: qbittorrent
  network_mode: service:gluetun    # ← Shares Gluetun's network
  depends_on:
    - gluetun
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
    - WEBUI_PORT=8085
  volumes:
    - /mnt/zpool/Docker/Stacks/arr-stack/qbittorrent:/config
    - /mnt/zpool/Media/Downloads:/downloads
  labels:
    - "traefik.enable=true"
    - "traefik.docker.network=backend_media"
    - "traefik.http.routers.qbittorrent.rule=Host(`qbit.a0a0.org`)"
    - "traefik.http.routers.qbittorrent.entrypoints=websecure"
    - "traefik.http.routers.qbittorrent.tls.certresolver=letsencrypt"
    - "traefik.http.services.qbittorrent.loadbalancer.server.port=8085"
```

**Why qBittorrent partially works:**
- Port 8085 exposed on Gluetun container
- Traefik labels present (but may not work correctly with network_mode: service)
- May be accessible via direct IP:8085 rather than through Traefik

### Other arr Services (Standard Pattern)

**Example: Sonarr**
```yaml
sonarr:
  image: lscr.io/linuxserver/sonarr:latest
  container_name: sonarr
  networks:
    - backend_media    # ← Normal network mode
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
  volumes:
    - /mnt/zpool/Docker/Stacks/arr-stack/sonarr:/config
    - /mnt/zpool/Media/Series:/tv
    - /mnt/zpool/Media/Downloads:/downloads
  ports:
    - 8989:8989
  labels:
    - "traefik.enable=true"
    - "traefik.docker.network=backend_media"
    - "traefik.http.routers.sonarr.rule=Host(`sonarr.a0a0.org`)"
    - "traefik.http.routers.sonarr.entrypoints=websecure"
    - "traefik.http.routers.sonarr.tls.certresolver=letsencrypt"
    - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
  restart: unless-stopped
```

**Pattern repeats for:** Radarr, Prowlarr, Readarr, Lidarr, Bazarr, Overseerr

---

## Management: Arcane

**What is Arcane:**
- Docker container management tool (similar to Dockge/Portainer)
- Provides GUI for compose file management
- Clever hybrid: GUI management + compose file deployment

**How it's running:**
- **Installed as:** TrueNAS Scale Docker app (not via compose)
- **Purpose:** Manages all other compose stacks
- **Benefit:**
  - Edit compose files in GUI or via Git
  - Deploy/update from web interface
  - View logs, manage containers
  - All while maintaining compose file format

**Note:** Only Arcane runs as TrueNAS app; all other services deployed via compose through Arcane.

---

## Debugging Checklist (For Future Session)

### 1. Check Container Status
```bash
ssh lavadmin@truenas.a0a0.org
cd /mnt/zpool/Docker/Projects/arr-stack
docker compose ps
```

**Expected:** All containers running
**Check for:** Restart loops, error states

### 2. Verify VPN Connection
```bash
# Check Gluetun VPN status
docker logs gluetun | tail -50

# Verify external IP (should be VPN IP, not 192.168.x.x)
docker exec gluetun curl -s ifconfig.me

# Test qBittorrent uses same IP
docker exec qbittorrent curl -s ifconfig.me
```

### 3. Network Connectivity Tests

**From host to containers:**
```bash
# Test direct container access (bypass Traefik)
curl http://localhost:8989  # Sonarr
curl http://localhost:7878  # Radarr
curl http://localhost:9696  # Prowlarr
```

**From Traefik to containers:**
```bash
docker exec traefik ping sonarr
docker exec traefik ping radarr
docker exec traefik wget -O- http://sonarr:8989
```

### 4. Traefik Routing Inspection

**Check Traefik dashboard:**
- URL: https://docker.a0a0.org
- Look for arr-stack routers in HTTP section
- Verify backend servers show as "healthy"

**Check Traefik logs:**
```bash
docker logs traefik | grep -i error
docker logs traefik | grep sonarr
docker logs traefik | grep radarr
```

### 5. Docker Network Inspection

```bash
# Verify backend_media network exists
docker network inspect backend_media

# Check which containers are connected
docker network inspect backend_media | grep Name

# Verify Traefik is on the network
docker inspect traefik | grep -A 20 Networks
```

### 6. DNS Resolution

```bash
# From host
nslookup sonarr.a0a0.org
nslookup docker.a0a0.org

# Should resolve to 192.168.40.6

# Test from inside Traefik container
docker exec traefik nslookup sonarr
docker exec traefik ping -c 2 sonarr
```

### 7. Port Exposure Check

```bash
# Verify ports are exposed on host
netstat -tlnp | grep :8989  # Sonarr
netstat -tlnp | grep :7878  # Radarr

# Check if Traefik can reach them
docker exec traefik nc -zv sonarr 8989
```

---

## Potential Root Causes

### Theory 1: VPN Routing Conflict
- Gluetun's TUN device may be affecting routing for other containers
- `backend_media` network traffic might be getting routed through VPN
- **Test:** Temporarily stop Gluetun, see if other services work

### Theory 2: Network Namespace Isolation
- qBittorrent using `network_mode: service:gluetun` may isolate it from backend_media
- Traefik can't route to qBittorrent properly (even though it's "accessible")
- **Test:** Check if qbit.a0a0.org works via Traefik or only via direct IP

### Theory 3: Traefik Label Misconfiguration
- `traefik.docker.network=backend_media` on qBittorrent may conflict with `network_mode: service:gluetun`
- Traefik expects container on backend_media, but qBittorrent is in Gluetun's network
- **Test:** Remove qBittorrent Traefik labels, access via IP:8085 only

### Theory 4: Docker Network MTU Issues
- VPN tunnel MTU mismatch with Docker bridge network
- Packets getting fragmented or dropped
- **Test:** Check MTU on all networks, adjust if needed

### Theory 5: Container Startup Order
- Services starting before networks fully initialized
- Race condition with Traefik discovering containers
- **Test:** Restart all containers in order: Traefik → Gluetun → arr services

---

## Quick Fix Attempts

### Attempt 1: Restart Everything in Order
```bash
cd /mnt/zpool/Docker/Projects
docker compose -f traefik3/compose.yaml restart
sleep 5
cd arr-stack
docker compose restart gluetun
sleep 10
docker compose restart
```

### Attempt 2: Recreate backend_media Network
```bash
# Stop all services on the network
docker compose -f arr-stack/compose.yaml down
docker compose -f jellyfin/compose.yaml down
# [stop others...]

# Recreate network
docker network rm backend_media
docker network create backend_media

# Restart Traefik, then arr-stack
```

### Attempt 3: Bypass VPN for Testing
**Temporarily modify arr-stack/compose.yaml:**
- Comment out `network_mode: service:gluetun` on qBittorrent
- Add `networks: [backend_media]` to qBittorrent
- Test if routing works without VPN

### Attempt 4: Check Arcane Deployment
- Access Arcane web interface
- Review arr-stack deployment logs
- Check if compose file was fully applied
- Look for warnings about network configuration

---

## Files to Check

**Compose files:**
- [arr-stack/compose.yaml](/mnt/truenas-projects/arr-stack/compose.yaml)
- [traefik3/compose.yaml](/mnt/truenas-projects/traefik3/compose.yaml)

**Environment:**
- [arr-stack/.env](/mnt/truenas-projects/arr-stack/.env)
- [traefik3/.env](/mnt/truenas-projects/traefik3/.env)

**Logs (remote):**
```bash
ssh lavadmin@truenas.a0a0.org
cd /mnt/zpool/Docker/Stacks/traefik3
tail -f traefik/logs/access.log
```

**Container data:**
```
/mnt/zpool/Docker/Stacks/arr-stack/
├── gluetun/
├── qbittorrent/
├── sonarr/
├── radarr/
├── prowlarr/
├── readarr/
├── lidarr/
├── bazarr/
└── overseerr/
```

---

## Known Working Services (Reference)

These services work correctly with Traefik + backend_media:
- ✅ **Jellyfin:** https://jellyfin.a0a0.org
- ✅ **Homarr:** https://home.a0a0.org
- ✅ **Dozzle:** https://dozzle.a0a0.org
- ✅ **FreshRSS:** https://rss.a0a0.org
- ✅ **Traefik Dashboard:** https://docker.a0a0.org

**Why they work:**
- Standard Docker networking (no VPN complications)
- Connected to backend_media or backend_storage
- Proper Traefik labels
- No network_mode overrides

---

## Next Steps for Debugging

1. **Document current state** (this file ✅)
2. **Check Arcane logs** - See if deployment had errors
3. **Verify VPN status** - Is Gluetun actually connected?
4. **Test container connectivity** - Can Traefik reach arr services?
5. **Review Traefik routing** - Are routers/services registered?
6. **Isolate qBittorrent issue** - Is it really accessible via Traefik or just direct?
7. **Test without VPN** - Temporarily disable Gluetun to rule out VPN routing
8. **Check network bridges** - Verify Docker networks configured correctly
9. **MTU investigation** - Check for packet fragmentation
10. **Review Arcane deployment** - Ensure compose applied correctly

---

## Useful Commands Reference

```bash
# SSH access
ssh lavadmin@truenas.a0a0.org

# Navigate to projects
cd /mnt/zpool/Docker/Projects/arr-stack

# Container management
docker compose ps                    # Status
docker compose logs -f sonarr        # Live logs
docker compose restart sonarr        # Restart single service
docker compose up -d --force-recreate # Recreate all

# Network debugging
docker network ls
docker network inspect backend_media
docker exec traefik ping sonarr

# VPN testing
docker exec gluetun curl ifconfig.me
docker logs gluetun | grep -i connected

# Traefik debugging
docker logs traefik | grep -i error
docker logs traefik | grep sonarr
curl -H "Host: sonarr.a0a0.org" http://192.168.40.6

# Check what's listening
netstat -tlnp | grep -E "(8989|7878|9696)"
```

---

## Additional Context

### Why This Setup is Clever

**VLAN Isolation:**
- Docker traffic on dedicated VLAN (192.168.40.6)
- Separates container network from main LAN
- Single entry point for all services

**Wildcard DNS + Traefik:**
- All `*.a0a0.org` → CNAME → docker.a0a0.org → 192.168.40.6
- Traefik handles routing based on hostname
- Single IP, automatic SSL for all services

**Arcane for Management:**
- TrueNAS app provides GUI
- Still uses compose files (not proprietary)
- Can manage via web or git/ssh
- Best of both worlds

**VPN Only for Torrents:**
- Only qBittorrent routed through VPN
- Other services direct connection
- Prevents VPN disconnections from breaking media management

---

## Open Questions

1. **Is qBittorrent truly accessible via Traefik or just direct IP?**
2. **Why only arr-stack affected when Jellyfin/Homarr work fine on backend_media?**
3. **Does Arcane have deployment logs showing network errors?**
4. **Is there a TrueNAS-specific network configuration affecting Docker?**
5. **Are arr-stack containers actually starting successfully?**
6. **Is Gluetun's VPN tunnel actually established?**

---

**Last Updated:** 2025-12-01
**Status:** Ready for debugging session
**Priority:** High - Media automation stack down
