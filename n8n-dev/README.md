# n8n-dev - Development/Experimentation Environment

**Access:** https://n8n-dev.a0a0.org

## Purpose

SQLite-based n8n deployment for experimentation and workflow development.

**Use this for:**
- Testing new workflows
- Learning n8n
- Proof of concept development
- Low-stakes experimentation

**For production:** See `../n8n-prod/` (PostgreSQL-based, production-ready)

## Database: SQLite

- Single container, zero dependencies
- Database: `/mnt/zpool/Docker/Stacks/n8n-dev/data/database.sqlite`
- Encryption key: `/mnt/zpool/Docker/Secrets/n8n-dev.env`

## UID/GID

n8n runs as UID 1000 internally (node user) and does NOT respect PUID/PGID environment variables. Data directory must be owned by 1000:1000.

## Deployment

```bash
# Create data directory with correct ownership
./build_stack_data.sh

# Deploy container
cd /mnt/zpool/Docker/Projects/n8n-dev
sudo docker compose up -d
```

## Cleanup

```bash
./remove_data.sh  # Interactive confirmation
```
