# Software Bill of Materials (BOM)

**Generated:** 2025-12-04
**Host:** truenas.a0a0.org (192.168.40.6)
**Purpose:** Inventory for backup/migration strategy, security auditing, and disaster recovery

---

## Host Environment

| Component | Version | Details |
|-----------|---------|---------|
| Operating System | Debian GNU/Linux 12 (bookworm) | TrueNAS Scale |
| Kernel | 6.12.15-production+truenas | |
| Docker Engine | (runtime) | Managed by TrueNAS |
| Architecture | linux/amd64 | |

---

## Container Inventory

### Media Automation Stack (arr-stack)

| Container | Image | Version | Base OS | Technology | Registry | Networks |
|-----------|-------|---------|---------|------------|----------|----------|
| qbittorrent | linuxserver/qbittorrent | latest | Alpine 3.22 | Qt/libtorrent | lscr.io | gluetun (network_mode) |
| sonarr | linuxserver/sonarr | latest | Alpine 3.22 | .NET/Mono | lscr.io | backend_media |
| radarr | linuxserver/radarr | latest | Alpine 3.22 | .NET/Mono | lscr.io | backend_media |
| lidarr | linuxserver/lidarr | latest | Alpine 3.22 | .NET/Mono | lscr.io | backend_media |
| readarr | hotio/readarr | latest | Alpine 3.22 | .NET/Mono | ghcr.io | backend_media |
| bazarr | linuxserver/bazarr | latest | Alpine 3.22 | Python | lscr.io | backend_media |
| prowlarr | linuxserver/prowlarr | latest | Alpine 3.22 | .NET/Mono | lscr.io | backend_media |
| jellyseerr | fallenbagel/jellyseerr | latest | Alpine 3.22 | Node.js | docker.io | backend_media |
| gluetun | qmcgaw/gluetun | latest | Alpine 3.22 | Go | docker.io | backend_media |
| flaresolverr | flaresolverr/flaresolverr | latest | Debian 12 | Python/Chromium | ghcr.io | backend_media |

**Notes:**
- qbittorrent routes through gluetun VPN (`network_mode: service:gluetun`)
- All *arr apps use PUID/PGID 568 (TrueNAS apps user)
- VPN credentials stored in `/mnt/zpool/Docker/Secrets/arr-stack.env`

### Media Streaming

| Container | Image | Version | Base OS | Technology | Registry | Networks |
|-----------|-------|---------|---------|------------|----------|----------|
| jellyfin | jellyfin/jellyfin | latest (10.11.3) | Debian 13 | .NET/FFmpeg | docker.io | backend_media |

**Notes:**
- Jellyfin config owned by root:apps (anomaly - should be apps:apps)
- Hardware acceleration capable (not currently configured)

### Infrastructure & Management

| Container | Image | Version | Base OS | Technology | Registry | Networks |
|-----------|-------|---------|---------|------------|----------|----------|
| traefik | traefik | latest (v3.2) | Alpine 3.22 | Go | docker.io | backend_media, backend_storage, traefik_public |
| arcane | getarcaneapp/arcane | latest | Debian 13 | Node.js | ghcr.io | backend_storage |
| homarr | homarr-labs/homarr | latest | Alpine 3.22 | Node.js | ghcr.io | backend_media |
| dozzle | amir20/dozzle | latest | Alpine 3.22 | Go | docker.io | backend_media |
| gitea | gitea/gitea | latest | Alpine 3.22 | Go | docker.io | backend_storage |

**Notes:**
- Traefik exposed on ports 80, 443, 8080 (dashboard)
- Traefik and Arcane both mount `/var/run/docker.sock` (privileged)
- Arcane manages own users (authentication separate from container UID/GID)
- Gitea manages own users (git user inside container)

### Utilities

| Container | Image | Version | Base OS | Technology | Registry | Networks |
|-----------|-------|---------|---------|------------|----------|----------|
| freshrss | linuxserver/freshrss | latest | Alpine 3.22 | PHP | lscr.io | backend_media |
| cyberchef | mpepping/cyberchef | latest | Alpine 3.22 | Nginx/JavaScript | docker.io | backend_storage |
| ladder | wasi-master/13ft | latest | Alpine 3.19 | Python/Flask | ghcr.io | backend_media |
| it-tools | corentinth/it-tools | latest | Alpine 3.20 | Node.js/Vue | docker.io | backend_storage |
| filebrowser | filebrowser/filebrowser | latest | Scratch | Go (static) | docker.io | backend_storage |

**Notes:**
- FreshRSS owned by UID/GID 911 (anomaly - not standard apps user)
- Filebrowser runs as 568:568 but manages own internal user database
- Filebrowser admin password retrieved from container logs on first start

### Storage

| Container | Image | Version | Base OS | Technology | Registry | Networks |
|-----------|-------|---------|---------|------------|----------|----------|
| minio | minio/minio | latest | (Not running) | Go | docker.io | backend_storage |

**Notes:**
- MinIO credentials stored in `/mnt/zpool/Docker/Secrets/minio.env`
- Exposes two endpoints: API (9000) and Console (9001)
- Data stored in `/mnt/zpool/Docker/Stacks/minio`

---

## Network Topology

| Network | Driver | Scope | Connected Containers | Purpose |
|---------|--------|-------|---------------------|---------|
| backend_media | bridge | local | traefik, jellyfin, sonarr, radarr, lidarr, readarr, bazarr, prowlarr, jellyseerr, gluetun, flaresolverr, homarr, dozzle, ladder, freshrss | Media services and *arr stack |
| backend_storage | bridge | local | traefik, arcane, gitea, cyberchef, it-tools, filebrowser | Infrastructure and utilities |
| traefik3_traefik_public | bridge | local | traefik | External ingress |

**Network Isolation:**
- Media services isolated from infrastructure services
- Traefik bridges both networks for reverse proxy
- No direct container-to-container communication across networks (except via Traefik)

**Security Notes:**
- qbittorrent traffic routed through gluetun VPN (no direct network access)
- Docker socket exposed to: traefik (read-only), arcane (read-write)

---

## Technology Stack Summary

### By Runtime/Framework

| Technology | Container Count | Containers | CVE Tracking |
|------------|----------------|------------|--------------|
| Go | 6 | traefik, dozzle, gitea, gluetun, filebrowser, minio* | golang.org/security |
| .NET/Mono | 6 | sonarr, radarr, lidarr, readarr, prowlarr, jellyfin | dotnet.microsoft.com/security |
| Node.js | 4 | arcane, homarr, jellyseerr, it-tools | nodejs.org/security |
| Python | 3 | bazarr, flaresolverr, ladder | python.org/security |
| PHP | 1 | freshrss | php.net/security |
| Qt/C++ | 1 | qbittorrent | qt.io/security |
| Static Web | 1 | cyberchef | N/A (client-side JS) |

*minio not currently running

### By Base OS

| Base OS | Container Count | Security Updates |
|---------|----------------|------------------|
| Alpine Linux 3.22 | 15 | alpinelinux.org/security |
| Alpine Linux 3.20 | 1 | alpinelinux.org/security |
| Alpine Linux 3.19 | 1 | alpinelinux.org/security |
| Debian 13 (trixie) | 2 | debian.org/security |
| Debian 12 (bookworm) | 1 | debian.org/security |
| Scratch (no OS) | 1 | N/A (static binary) |

**Vulnerability Management:**
- Track Alpine CVEs for majority of containers (17/21)
- .NET/Mono requires separate CVE monitoring
- Node.js vulnerabilities affect 4 containers
- Debian containers may need manual security updates

---

## Volume Mappings

### Critical Persistent Data

| Host Path | Purpose | Owner | Critical for Backup |
|-----------|---------|-------|---------------------|
| `/mnt/zpool/Docker/Stacks/traefik/acme/acme.json` | Let's Encrypt certificates | root | **CRITICAL** |
| `/mnt/zpool/Docker/Secrets/*.env` | Service credentials | root:root | **CRITICAL** |
| `/mnt/zpool/Docker/Stacks/gitea/` | Git repositories | apps:apps | **CRITICAL** |
| `/mnt/zpool/Docker/Stacks/arcane/` | Arcane database | apps:apps | **HIGH** |
| `/mnt/zpool/Docker/Stacks/jellyfin/config/` | Jellyfin metadata | root:apps | **HIGH** |
| `/mnt/zpool/Docker/Stacks/arr-stack/*/data/` | *arr databases | apps:apps | **HIGH** |
| `/mnt/zpool/Docker/Stacks/filebrowser/` | Filebrowser DB & config | apps:apps | **MEDIUM** |
| `/mnt/zpool/Docker/Stacks/homarr/` | Dashboard config | apps:apps | **MEDIUM** |
| `/mnt/zpool/Docker/Stacks/freshrss/` | RSS feed data | 911:911 | **MEDIUM** |
| `/mnt/zpool/Docker/Stacks/minio/` | S3 object storage | apps:apps | **HIGH** |

### Media Libraries (Ephemeral - Can Be Reacquired)

| Host Path | Purpose | Owner | Critical for Backup |
|-----------|---------|-------|---------------------|
| `/mnt/zpool/Media/Movies/` | Radarr managed films | apps:apps | LOW |
| `/mnt/zpool/Media/Series/` | Sonarr managed TV | apps:apps | LOW |
| `/mnt/zpool/Media/Music/` | Lidarr managed music | apps:apps | LOW |
| `/mnt/zpool/Media/Books/` | Readarr managed books | apps:apps | LOW |
| `/mnt/zpool/Media/Downloads/` | Torrent downloads | apps:apps | LOW |

### Configuration Mounts

| Host Path | Container Path | Container | Notes |
|-----------|----------------|-----------|-------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | traefik | Read-only |
| `/var/run/docker.sock` | `/var/run/docker.sock` | arcane | Read-write |
| `/etc/localtime` | `/etc/localtime` | (all) | Read-only |
| `/mnt/zpool/Docker/Projects/` | `/app/data/projects` | arcane | |
| `/mnt/zpool/Docker/Stacks/` | `/app/data/stacks` | arcane | |
| `/mnt/zpool/Docker/Secrets/` | `/mnt/zpool/Docker/Secrets` | arcane | Read-only |

### Filebrowser Browse Access

| Host Path | Container Path | Access |
|-----------|----------------|--------|
| `/mnt/zpool/Docker` | `/srv/Docker` | Read-write |
| `/mnt/zpool/Media` | `/srv/Media` | Read-write |
| `/mnt/zpool/storage-nfs` | `/srv/storage-nfs` | Read-write |
| `/mnt/zpool/storage-share` | `/srv/storage-smb` | Read-write |

---

## File Ownership Patterns

### Standard Pattern (Expected)

```
Owner: apps:apps (568:568)
Applies to: Most application config directories in /mnt/zpool/Docker/Stacks/
```

### Anomalies (Non-Standard)

| Path | Owner | Expected | Reason | Security Impact |
|------|-------|----------|--------|-----------------|
| `/mnt/zpool/Docker/Stacks/freshrss/` | 911:911 | apps:apps | LinuxServer.io default UID | Low - isolated container |
| `/mnt/zpool/Docker/Stacks/jellyfin/` | root:apps | apps:apps | Jellyfin requires root for hardware access | Medium - root inside container |
| `/mnt/zpool/Docker/Secrets/` | root:root | root:root | **Expected** - secrets should be root-only | Correct - high security |
| `/mnt/zpool/Docker/Stacks/traefik/acme.json` | root | root | **Expected** - SSL certificates | Correct - critical security |

### Internal User Management (Container-Specific)

These containers manage their own user databases **separate** from container UID/GID:

| Container | Internal Users | Authentication | Admin Access |
|-----------|---------------|----------------|--------------|
| filebrowser | Own database | HTTP Basic/Form | Password in logs on first start |
| gitea | Own database | Git/HTTP/SSH | Setup wizard |
| arcane | Own database | JWT token | Setup wizard |
| jellyfin | Own database | HTTP/API | Setup wizard |

**Security Note:** These containers run as specific UIDs (568 or root) but manage application-level authentication separately.

---

## Secrets Management

### Secrets Location

```
/mnt/zpool/Docker/Secrets/
├── arcane.env          (ENCRYPTION_KEY, JWT_SECRET)
├── arr-stack.env       (OPENVPN_USER, OPENVPN_PASSWORD)
├── homarr.env          (API keys, credentials)
├── minio.env           (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD)
└── traefik.env         (LINODE_TOKEN for DNS challenge)
```

**Ownership:** root:root (0600 permissions)

### Secrets Consumption

| Container | Secrets File | Method | Variables |
|-----------|-------------|--------|-----------|
| traefik | traefik.env | env_file | LINODE_TOKEN |
| arcane | arcane.env | env_file | ENCRYPTION_KEY, JWT_SECRET |
| gluetun | arr-stack.env | env_file | OPENVPN_USER, OPENVPN_PASSWORD |
| minio | minio.env | env_file | MINIO_ROOT_USER, MINIO_ROOT_PASSWORD |
| homarr | homarr.env | env_file | Various API keys |

**Security Practice:**
- Secrets NOT in compose files
- Secrets NOT in stack .env files
- Secrets isolated in root-only directory
- Secrets backed up to ZFS dataset with encryption

---

## Registry Summary

| Registry | Containers | Trust Level | Notes |
|----------|------------|-------------|-------|
| lscr.io | 7 | High | LinuxServer.io official images |
| docker.io | 5 | Medium | Docker Hub official/verified |
| ghcr.io | 6 | Medium | GitHub Container Registry |
| qmcgaw | 1 (gluetun) | Medium | Well-known VPN client |
| fallenbagel | 1 (jellyseerr) | Medium | Popular Jellyfin companion |
| mpepping | 1 (cyberchef) | Low | Community maintained |

**Security Recommendation:** Pin versions instead of using `latest` tags for production stability and security auditing.

---

## Backup Priority Matrix

### Tier 1 - Critical (Must Have for Recovery)

```
/mnt/zpool/Docker/Secrets/           → All service credentials
/mnt/zpool/Docker/Stacks/traefik/acme/acme.json → SSL certificates
/mnt/zpool/Docker/Stacks/gitea/      → Git repositories
```

**Recovery Impact:** Cannot restore services without these.
**Backup Frequency:** Daily
**Retention:** 30 days

### Tier 2 - High (Significant Data Loss)

```
/mnt/zpool/Docker/Stacks/arcane/     → Docker management config
/mnt/zpool/Docker/Stacks/jellyfin/config/ → Media metadata
/mnt/zpool/Docker/Stacks/arr-stack/  → *arr databases and settings
/mnt/zpool/Docker/Stacks/minio/      → Object storage data
```

**Recovery Impact:** Lose configuration, metadata, watch history.
**Backup Frequency:** Daily
**Retention:** 14 days

### Tier 3 - Medium (Convenience Loss)

```
/mnt/zpool/Docker/Stacks/filebrowser/ → User preferences
/mnt/zpool/Docker/Stacks/homarr/     → Dashboard layout
/mnt/zpool/Docker/Stacks/freshrss/   → RSS feed state
```

**Recovery Impact:** Lose preferences, can be recreated.
**Backup Frequency:** Weekly
**Retention:** 7 days

### Tier 4 - Low (Recreatable)

```
/mnt/zpool/Media/                    → Media files
/mnt/zpool/Docker/Stacks/*/cache/    → Application caches
```

**Recovery Impact:** Can be reacquired or regenerated.
**Backup Frequency:** Optional
**Retention:** N/A

---

## Migration Checklist

When migrating to new hardware:

### Pre-Migration
- [ ] Document all running containers: `docker ps`
- [ ] Backup Tier 1 & 2 data
- [ ] Export network configurations
- [ ] Save current Docker images list
- [ ] Document custom DNS records
- [ ] Test backup restoration on test system

### Migration Steps
1. [ ] Install Docker on new host
2. [ ] Create network: `docker network create backend_media backend_storage`
3. [ ] Restore `/mnt/zpool/Docker/` directory structure
4. [ ] Restore secrets (verify root:root ownership)
5. [ ] Restore Traefik acme.json (verify permissions 600)
6. [ ] Update `.env.global` with new paths (if changed)
7. [ ] Run `./sync-env.sh`
8. [ ] Deploy Traefik first (wait for SSL certs)
9. [ ] Deploy remaining stacks
10. [ ] Verify DNS records point to new host
11. [ ] Test all service endpoints

### Post-Migration Verification
- [ ] All containers running: `docker ps`
- [ ] No container restarts: `docker ps --filter "status=restarting"`
- [ ] SSL certificates valid
- [ ] All services accessible via HTTPS
- [ ] Internal authentication working (Jellyfin, Gitea, etc.)
- [ ] VPN connection active (gluetun)
- [ ] Media playback functional
- [ ] Download automation working

---

## Cybersecurity Attack Surface

### Exposed Services (Internet-Facing via Traefik)

| Service | Port | Protocol | Authentication | Risk Level |
|---------|------|----------|----------------|------------|
| Traefik Dashboard | 443 | HTTPS | HTTP Basic Auth | Medium |
| Jellyfin | 443 | HTTPS | Internal user DB | Medium |
| Jellyseerr | 443 | HTTPS | Internal user DB | Medium |
| Gitea | 443 | HTTPS | Internal user DB | High (code repo) |
| Arcane | 443 | HTTPS | JWT + Internal DB | **HIGH** (Docker control) |
| Homarr | 443 | HTTPS | None (dashboard) | Low |
| Filebrowser | 443 | HTTPS | Internal user DB | **HIGH** (file access) |
| Other utilities | 443 | HTTPS | Varies | Low |

### Privileged Containers

| Container | Privilege | Justification | Mitigation |
|-----------|-----------|---------------|------------|
| traefik | Docker socket (RO) | Service discovery | Read-only mount |
| arcane | Docker socket (RW) | Container management | Authentication required |
| gluetun | NET_ADMIN capability | VPN tunnel | Isolated network |

### Critical Files for Integrity Monitoring

```
/mnt/zpool/Docker/Stacks/traefik/acme/acme.json
/mnt/zpool/Docker/Secrets/*.env
/mnt/zpool/Docker/Stacks/*/compose.yaml
/mnt/zpool/Docker/.env.global
```

**Recommendation:** Implement file integrity monitoring (e.g., AIDE, Tripwire) on these paths.

### Secrets Exposure Risk

**High Risk:**
- Arcane has read access to `/mnt/zpool/Docker/Secrets/` (intentional for stack management)
- Traefik has LINODE_TOKEN (DNS-01 challenge) - can create arbitrary DNS records

**Mitigation:**
- Secrets directory mounted read-only to Arcane
- Strong authentication on Arcane web interface
- API tokens with minimal scope (Linode: DNS only)

---

## Compliance & Audit Notes

**Generated:** 2025-12-04
**Next Review:** Required before each Pull Request
**Maintained By:** Project owner + Claude Code AI

### Change Log

| Date | Change | Reason |
|------|--------|--------|
| 2025-12-04 | Initial BOM creation | Establish baseline for backup/migration strategy |

### Update Process

1. Before each PR: Update this BOM
2. Document any new containers, networks, or volume mappings
3. Note any ownership anomalies
4. Review security implications of changes
5. Update backup priority if new critical data paths added

---

## Notes for Developers

### When Adding New Containers

1. **Update BOM Sections:**
   - Container Inventory table
   - Network Topology (if new network)
   - Volume Mappings (all mounts)
   - File Ownership (check for anomalies)
   - Backup Priority (classify data)

2. **Security Review:**
   - Does it expose services to internet?
   - Does it need Docker socket access?
   - Does it manage own users?
   - What secrets does it require?

3. **Document Anomalies:**
   - Non-standard UID/GID
   - Internal user management
   - Special permission requirements
   - Root containers

### Base Image Information

To determine base OS for new containers:
```bash
docker exec <container> cat /etc/os-release
```

### Volume Inspection

To see all mounts for a container:
```bash
docker inspect <container> --format '{{.Mounts}}'
```

---

**END OF BOM**
