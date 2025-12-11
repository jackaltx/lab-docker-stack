# TrueNAS Docker Lab Stack

> **⚠️ EXPERIMENTAL - VERY EARLY STAGE**
>
> Development experiment, not production ready. Works but evolving.
>
> **USE AT YOUR OWN RISK**

Self-hosted Docker infrastructure on TrueNAS Scale (should work on any Debian-based system), bypassing built-in Apps for control and portability.

## Overview

Docker Compose configurations for a complete self-hosted media and infrastructure stack. Runs directly on TrueNAS using standard Docker Compose, managed through [Arcane](https://github.com/getarcaneapp/arcane) GUI.

### AI-Assisted Development Experiment

The real feature is the development methodology: using Claude Code to create, update, and test on a remote system. This is "vibe coding" - setting goals and expectations, then collaborating with AI to realize concepts through documentation and implementation.  I am hoping this will grow into an AI IDE for building systems of systems at the small home/test lab level.

As the project builds, lessons learned provide AI context for what's required. Goal: quickly realize standalone containers, then progressively more complicated stacks. Realizing means engineering the product. Development happens in sprints: build, test, deploy, verify. Verification is the hardest part.

Part of the larger **[SOLTI](https://github.com/jackaltx/solti-dev)** exploration project (AI co-developed)

**Why bypass TrueNAS Apps?**

- Full control over compose files and configurations
- Standard Docker workflows (no proprietary formats)
- Simplify migration and version control
- Better suited for complex multi-service stacks (a purty way to day  "Rats, I already used that port on this machine.")

## Key Features

- **Reverse Proxy:** Traefik v3 with automatic HTTPS (Let's Encrypt DNS challenge)
- **Media Automation:** Complete *arr stack with VPN (12+ services: Sonarr, Radarr, Readarr, Lidarr, Prowlarr, Bazarr, Jellyseerr, qBittorrent, and automation tools)
- **Media Streaming:** Jellyfin with Jellyseerr request management
- **Management:** Arcane (Docker Compose GUI), Homarr dashboard, Dozzle real-time logs
- **Storage:** MinIO S3-compatible object storage, FileBrowser web interface
- **Development:** Gitea self-hosted Git, Redis cache
- **Utilities:** FreshRSS, 13ft-ladder, IT-Tools, CyberChef
- **Profile-Based Configuration:** Multi-environment support with git-safe workflows

## Architecture

- **Network Segmentation:** Separate `backend_storage` and `backend_media` Docker bridge networks
- **Secrets Management:** ZFS dataset isolation (see [docs/Secrets-Management.md](docs/Secrets-Management.md))
- **DNS Domain Pattern:** Wildcard CNAME to single A record providing automated SSL for all services (e.g., `*.example.com → docker.example.com → 192.168.x.x`)
- **Profile Templates:** Site-specific configuration isolated in profile files with `sync-env.sh` for multi-environment deployment
- **VPN Kill-Switch:** Gluetun with Private Internet Access providing network-isolated VPN for torrent traffic 

## Claude Code Project

**Claude Code managed project** - all architectural decisions, patterns, and workflows documented for AI-assisted development.

### Developer Instructions

- **Start here:** [CLAUDE.md](CLAUDE.md) - Complete system documentation
- **Deployment:** [docs/Portable-Deployment.md](docs/Portable-Deployment.md) - Portable path configuration
- **Inventory:** [docs/SOFTWARE-BOM.md](docs/SOFTWARE-BOM.md) - Bill of Materials for backup/migration/security
- **Secrets:** [docs/Secrets-Management.md](docs/Secrets-Management.md) - ZFS dataset strategy
- **UID/GID:** [docs/UID-GID-Strategy.md](docs/UID-GID-Strategy.md) - Permission management

### Monitoring with Claude Code

This project includes custom slash commands for monitoring and verification when using [Claude Code](https://claude.ai/claude-code).

**Available Commands:**

- **`/stack-status`** - Complete Docker stack health check
  - Lists all containers with status and uptime
  - Checks for health issues and errors in logs
  - Generates timestamped report in `status-reports/`
  - Identifies services needing attention

- **`/verify-routes`** - Traefik routing verification
  - Tests DNS resolution for all services
  - Validates SSL certificates and expiration dates
  - Checks HTTP/HTTPS connectivity
  - Identifies configuration mismatches
  - Generates detailed routing report

**Getting Started with Claude Code:**

1. Sign up for Claude at [claude.ai/claude-code](https://claude.ai/claude-code)
2. Install the CLI tool following the official documentation
3. Clone this repository and navigate to the project directory
4. Run `/stack-status` or `/verify-routes` to generate reports

Reports are saved to `status-reports/` with timestamps for tracking changes over time.

## Quick Start

### Profile-Based Configuration

Environment values are managed via **profile templates** that sync to all stack `.env` files:

- **`.env.global`** - Generic defaults for development/main branch
- **`a0a0.env`** - TrueNAS production values (example)
- **`dockarr.env`** - VM testing values (example)

Create your own profile or use `.env.global` as a starting point.

### Initial Setup

```bash
# Clone repository
git clone https://github.com/jackaltx/true-lab-docker-stack.git
cd true-lab-docker-stack

# Option 1: Use generic defaults (for development)
./sync-env.sh -f .env.global -u
# Edit values: DOCKER_ROOT, MEDIA_ROOT, DOMAIN, PUID, PGID

# Option 2: Create site-specific profile
cp .env.global mysite.env
vim mysite.env                     # Customize for your environment
./sync-env.sh -f mysite.env -p     # Sync + protect from git commits

# Review deployment guide
cat docs/Portable-Deployment.md

# Services managed via Arcane GUI
# https://arcane.example.com
```

### Workflow Patterns

**Generic work (committing code):**
```bash
./sync-env.sh -f .env.global -u    # Reset to generic + allow commits
git add . && git commit
```

**Site-specific testing:**
```bash
./sync-env.sh -f mysite.env -p     # Apply site values + protect from commits
# Deploy and test services
```

See [docs/Portable-Deployment.md](docs/Portable-Deployment.md) for complete deployment workflow.

## Configuration Management

### sync-env.sh - Profile Manager

Manages environment variables across all stack `.env` files from central profile templates.

**Usage:**
```bash
./sync-env.sh -f <template> [-p|-u] [-h]

Options:
  -f <template>  Source template (REQUIRED: .env.global, a0a0.env, custom.env)
  -p             Protect: Add **/.env to .gitignore (for site-specific testing)
  -u             Unprotect: Remove from .gitignore (for committing baseline)
  -h             Show help
```

**What it syncs:**
- PUID, PGID, TZ (user/timezone)
- DOMAIN (for Traefik routing)
- DOCKER_ROOT, MEDIA_ROOT (base paths)

**Profile examples included:**
- `.env.global` - Generic defaults (PUID=1000, example.com, /opt/Docker)
- `a0a0.env` - TrueNAS production example (PUID=568, a0a0.org, /mnt/zpool)
- `dockarr.env` - VM testing example (PUID=1000, a0a0.org, ${HOME}/docker_stack)

Create custom profiles for different deployment targets (dev, staging, production).

## Services

All services accessible via HTTPS with automatic certificates:

### Infrastructure & Management

| Service | URL | Purpose |
|---------|-----|---------|
| Traefik | <https://docker.example.com> | Reverse proxy dashboard |
| Arcane | <https://arcane.example.com> | Docker Compose management GUI |
| Homarr | <https://home.example.com> | Service dashboard |
| Dozzle | <https://dozzle.example.com> | Real-time container logs |

### Media Stack (arr-stack)

Complete media automation suite with VPN (Gluetun):

| Service | URL | Purpose |
|---------|-----|---------|
| Jellyfin | <https://jellyfin.example.com> | Media streaming |
| Jellyseerr | <https://jellyseerr.example.com> | Media requests |
| Sonarr | <https://sonarr.example.com> | TV show management |
| Radarr | <https://radarr.example.com> | Movie management |
| Readarr | <https://readarr.example.com> | Book management |
| Lidarr | <https://lidarr.example.com> | Music management |
| Prowlarr | <https://prowlarr.example.com> | Indexer manager |
| Bazarr | <https://bazarr.example.com> | Subtitle automation |
| qBittorrent | <https://qbit.example.com> | Torrent client (via VPN) |

**arr-stack backend services:** Gluetun (VPN), FlareSolverr, Unpackerr, Recyclarr, Profilarr

### Storage & Development

| Service | URL | Purpose |
|---------|-----|---------|
| MinIO | <https://minio-true.example.com> | S3-compatible object storage |
| Gitea | <https://gitea.example.com> | Self-hosted Git service |
| FileBrowser | <https://files.example.com> | Web-based file manager |
| Redis | - | Development cache instance |

### Utilities

| Service | URL | Purpose |
|---------|-----|---------|
| FreshRSS | <https://rss.example.com> | RSS feed aggregator |
| 13ft-ladder | <https://ladder.example.com> | Paywall bypass |
| IT-Tools | <https://it-tools.example.com> | Developer utilities |
| CyberChef | <https://cyberchef.example.com> | Data transformation toolkit |

See [CLAUDE.md](CLAUDE.md#deployed-projects) for detailed configuration and deployment notes.

## Contributing

Personal infrastructure project. Use as reference for your own TrueNAS Docker deployments.

## License

MIT - Use freely, no warranty provided.
