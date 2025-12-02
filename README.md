# TrueNAS Docker Lab Stack

> **⚠️ EXPERIMENTAL - VERY EARLY STAGE**
>
> This is a development experiment, not production-ready software. Do not use without deep thought. Not suitable for internet-facing deployments.

> **USE AT YOUR RISK, PRACTICE SAFE HEX!**

Self-hosted Docker infrastructure developed on TrueNAS Scale (should work on any Debian distro - TBD), bypassing the built-in Apps system for maximum control and portability.

## Overview

This repository contains Docker Compose configurations for a complete self-hosted media and infrastructure stack. Developed directly on TrueNAS using standard Docker Compose, managed through [Arcane](https://github.com/getarcaneapp/arcane) for GUI control.

### AI-Assisted Development Experiment

The real feature here is the development methodology: using Claude Code to create, update, and test on a remote system. This is an experiment in "vibe coding" - setting goals and expectations, then collaborating with AI to realize concepts through documentation and implementation.

This repository is part of a larger project called **[SOLTI](https://github.com/jackaltx/solti-dev)** (AI co-developed)

**Why bypass TrueNAS Apps?**
- Full control over compose files and configurations
- Standard Docker workflows (no proprietary formats)
- Easy migration and version control
- Better suited for complex multi-service stacks

## Key Features

- **Reverse Proxy:** Traefik v3 with automatic HTTPS (Let's Encrypt DNS challenge)
- **Media Automation:** Complete *arr stack (Sonarr, Radarr, Prowlarr, etc.)
- **Media Streaming:** Jellyfin
- **Management:** Arcane, Homarr dashboard, Dozzle logs
- **Storage:** MinIO S3-compatible object storage
- **Git Hosting:** Gitea self-hosted Git service
- **Utilities:** FreshRSS, 13ft-ladder, IT-Tools, CyberChef

## Architecture

- **Network Segmentation:** Separate backend_storage and backend_media networks
- **Secrets Management:** ZFS dataset isolation (see [docs/Secrets-Management.md](docs/Secrets-Management.md))
- **Domain Pattern:** All services via `*.a0a0.org` with automatic SSL
- **VPN:** Gluetun with Private Internet Access for torrent traffic

## Claude Code Project

This is a **Claude Code managed project**. All architectural decisions, patterns, and workflows are documented for AI-assisted development.

### Developer Instructions

- **Start here:** [CLAUDE.md](CLAUDE.md) - Complete system documentation
- **Secrets:** [docs/Secrets-Management.md](docs/Secrets-Management.md) - ZFS dataset strategy
- **UID/GID:** [docs/UID-GID-Strategy.md](docs/UID-GID-Strategy.md) - Permission management

## Quick Start

```bash
# Clone repository
git clone https://github.com/jackaltx/lab-docker-stack.git
cd lab-docker-stack

# Review CLAUDE.md for full setup instructions
cat CLAUDE.md

# Services managed via Arcane GUI
# https://arcane.a0a0.org
```

## Services

All services accessible via HTTPS with automatic certificates:

| Service | URL | Purpose |
|---------|-----|---------|
| Traefik | https://docker.a0a0.org | Reverse proxy dashboard |
| Homarr | https://home.a0a0.org | Main dashboard |
| Arcane | https://arcane.a0a0.org | Docker management GUI |
| Jellyfin | https://jellyfin.a0a0.org | Media streaming |
| Overseerr | https://overseerr.a0a0.org | Media requests |
| Gitea | https://gitea.a0a0.org | Git hosting |
| MinIO | https://minio-true.a0a0.org | S3 storage console |
| Dozzle | https://dozzle.a0a0.org | Container logs |

See [CLAUDE.md](CLAUDE.md#deployed-projects) for complete service list and details.

## Contributing

This is a personal infrastructure project, but feel free to use it as a reference for your own TrueNAS Docker deployments.

## License

MIT - Use freely, no warranty provided.
