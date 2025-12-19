# n8n Deployment Comparison

## Quick Reference

| Feature | n8n-dev | n8n-prod |
|---------|---------|----------|
| **Database** | SQLite | PostgreSQL 16 |
| **Containers** | 1 (n8n only) | 2 (n8n + postgres) |
| **URL** | https://n8n-dev.a0a0.org | https://n8n.a0a0.org |
| **Purpose** | Experimentation | Production |
| **Deployment** | Local TrueNAS | Remote VM |
| **Backup** | Simple (1 directory) | Complex (2 directories or pg_dump) |
| **Downtime for backup** | Required | Optional (pg_dump) |
| **Multi-instance** | No (SQLite locks) | Yes (PostgreSQL supports it) |
| **Performance** | Good (single user) | Better (concurrent access) |
| **Complexity** | Low | Medium |
| **Data location** | `/mnt/zpool/Docker/Stacks/n8n-dev/data/` | `/mnt/zpool/Docker/Stacks/n8n-prod/{data,postgres}/` |
| **Secrets** | `/mnt/zpool/Docker/Secrets/n8n-dev.env` | `/mnt/zpool/Docker/Secrets/n8n-prod.env` |

## When to Use Each

### Use n8n-dev for:
- ✅ Learning n8n
- ✅ Testing new workflow ideas
- ✅ Proof of concept development
- ✅ Personal automation (non-critical)
- ✅ Quick deployment/teardown
- ✅ Minimal resource usage

### Use n8n-prod for:
- ✅ Business-critical workflows
- ✅ Remote VM deployment
- ✅ Multi-user access requirements
- ✅ High-availability needs
- ✅ Workflows that run frequently
- ✅ When you need queue mode (multiple n8n instances)

## Migration Path

**Develop → Test → Deploy:**

1. **Develop** in `n8n-dev` (SQLite, local TrueNAS)
   - Build and test workflow
   - Verify it works as expected

2. **Export** workflow from n8n-dev
   - Settings → Import/Export → Export workflow

3. **Import** to `n8n-prod` (PostgreSQL, remote VM)
   - Settings → Import/Export → Import from file

4. **Re-configure** credentials
   - Credentials encrypted with different keys
   - Must re-enter secrets in production

## Architecture Differences

### n8n-dev (Simple)
```
┌─────────────────┐
│  n8n-dev        │
│  (SQLite)       │
│  UID 1000       │
└─────────────────┘
        │
        ↓
backend_storage ←→ Traefik ←→ Internet
```

### n8n-prod (Dual-container)
```
┌─────────────────┐     n8n_prod_internal    ┌─────────────────┐
│  n8n            │◄────(private network)────►│  postgres       │
│  UID 1000       │                           │  UID 999        │
└─────────────────┘                           └─────────────────┘
        │                                             │
        ↓                                             │
backend_storage ←→ Traefik ←→ Internet               │
                                                      │
                                          (not exposed externally)
```

**Key difference:** PostgreSQL is isolated on private network, only accessible to n8n container.

## Backup Comparison

### n8n-dev Backup
```bash
# Stop container
sudo docker compose down

# Single directory backup
sudo tar -czf backup.tar.gz /mnt/zpool/Docker/Stacks/n8n-dev

# Restart
sudo docker compose up -d
```

**Pros:** Simple, single directory
**Cons:** Requires downtime

### n8n-prod Backup

**Option 1: Full backup (with downtime)**
```bash
# Stop containers
sudo docker compose down

# Backup both directories
sudo tar -czf backup.tar.gz /mnt/zpool/Docker/Stacks/n8n-prod

# Restart
sudo docker compose up -d
```

**Option 2: Database-only (no downtime)**
```bash
# Live backup, no container stop
sudo docker exec n8n-postgres pg_dump -U n8n n8n | gzip > backup.sql.gz
```

**Pros:** Option 2 has zero downtime
**Cons:** More complex, need to backup both data and database directories

## Resource Usage

### n8n-dev
- **Memory:** ~200-300MB (single container)
- **Disk:** Grows with workflow executions (SQLite database)
- **CPU:** Minimal (idle) to high (during workflow execution)

### n8n-prod
- **Memory:** ~400-500MB (n8n + PostgreSQL)
- **Disk:** Grows with workflow executions (PostgreSQL database)
- **CPU:** Minimal (idle) to high (during workflow execution)
- **Additional:** PostgreSQL background processes (autovacuum, checkpointer)

## Upgrade Strategy

### n8n-dev Upgrade
```bash
cd /mnt/zpool/Docker/Projects/n8n-dev
sudo docker compose pull
sudo docker compose up -d
```

### n8n-prod Upgrade
```bash
# Backup first (critical!)
sudo docker exec n8n-postgres pg_dump -U n8n n8n | gzip > pre-upgrade-backup.sql.gz

# Pull new images
cd /mnt/zpool/Docker/Projects/n8n-prod
sudo docker compose pull

# Upgrade (postgres migrations happen automatically)
sudo docker compose up -d

# Check logs for migration issues
sudo docker logs n8n
```

## Common Pitfall: Encryption Keys

**⚠️ CRITICAL:** Encryption keys differ between instances!

- `n8n-dev` has its own encryption key in `/mnt/zpool/Docker/Secrets/n8n-dev.env`
- `n8n-prod` has its own encryption key in `/mnt/zpool/Docker/Secrets/n8n-prod.env`

**Result:** Credentials cannot be migrated directly. You must:
1. Export workflow JSON (workflows export, credentials do NOT)
2. Import workflow to other instance
3. **Manually re-enter all credentials** in the new instance

**Never lose encryption keys** - credentials are unrecoverable without them!

## Decision Flowchart

```
Are you experimenting with n8n?
    ├─ Yes → Use n8n-dev
    └─ No  → Is this production-critical?
              ├─ Yes → Use n8n-prod
              └─ No  → Use n8n-dev (good enough)
```

## Summary

**n8n-dev:** SQLite, simple, local, perfect for learning and testing
**n8n-prod:** PostgreSQL, robust, remote VM-ready, production workflows

Start with n8n-dev, migrate to n8n-prod when you need reliability and remote deployment.
