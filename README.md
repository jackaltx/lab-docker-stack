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
- **Media Automation:** Complete *arr stack (Sonarr, Radarr, Prowlarr, etc.)
- **Media Streaming:** Jellyfin
- **Management:** Arcane, Homarr dashboard, Dozzle logs
- **Storage:** MinIO S3-compatible object storage
- **Git Hosting:** Gitea self-hosted Git service
- **Utilities:** FreshRSS, 13ft-ladder, IT-Tools, CyberChef

## Architecture

- **Network Segmentation:** Separate backend_storage and backend_media networks
- **Secrets Management:** ZFS dataset isolation (see [docs/Secrets-Management.md](docs/Secrets-Management.md))
- **DNS Domain Pattern:** All services mapped using CNAME to A record uisng single domain providing automated SSL. e.g., `https://jellyfin.example.com`
- **Simplied Templating** site specific information isolate in env file allows simple name-value customization.
- **VPN:** Using a Kill-Switch Private Internet Access front end for a private in-machine network. 

## Claude Code Project

**Claude Code managed project** - all architectural decisions, patterns, and workflows documented for AI-assisted development.

### Developer Instructions

- **Start here:** [CLAUDE.md](CLAUDE.md) - Complete system documentation
- **Deployment:** [docs/Portable-Deployment.md](docs/Portable-Deployment.md) - Portable path configuration
- **Inventory:** [docs/SOFTWARE-BOM.md](docs/SOFTWARE-BOM.md) - Bill of Materials for backup/migration/security
- **Secrets:** [docs/Secrets-Management.md](docs/Secrets-Management.md) - ZFS dataset strategy
- **UID/GID:** [docs/UID-GID-Strategy.md](docs/UID-GID-Strategy.md) - Permission management

## Quick Start

```bash
# Clone repository
git clone https://github.com/jackaltx/lab-docker-stack.git
cd lab-docker-stack

# Configure for your environment
vim .env.global              # Set DOCKER_ROOT, MEDIA_ROOT, DOMAIN
./sync-env.sh               # Sync to all stack .env files

# Review deployment guide
cat docs/Portable-Deployment.md

# Services managed via Arcane GUI
# https://arcane.a0a0.org
```

See [docs/Portable-Deployment.md](docs/Portable-Deployment.md) for complete deployment workflow.

## Services

All services accessible via HTTPS with automatic certificates:

| Service | URL | Purpose |
|---------|-----|---------|
| Traefik | <https://docker.a0a0.org> | Reverse proxy dashboard |
| Homarr | <https://home.a0a0.org> | Main dashboard |
| Arcane | <https://arcane.a0a0.org> | Docker management GUI |
| Jellyfin | <https://jellyfin.a0a0.org> | Media streaming |
| Overseerr | <https://overseerr.a0a0.org> | Media requests |
| Gitea | <https://gitea.a0a0.org> | Git hosting |
| MinIO | <https://minio-true.a0a0.org> | S3 storage console |
| Dozzle | <https://dozzle.a0a0.org> | Container logs |

See [CLAUDE.md](CLAUDE.md#deployed-projects) for complete service list and details.

## Contributing

Personal infrastructure project. Use as reference for your own TrueNAS Docker deployments.

## License

MIT - Use freely, no warranty provided.
