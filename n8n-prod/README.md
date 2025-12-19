# n8n-prod - Production Environment

**Access:** https://n8n.a0a0.org

## Purpose

PostgreSQL-based n8n deployment for production workflows intended for remote VM deployment.

**Use this for:**
- Production workflows
- Business-critical automation
- High-reliability requirements
- Multi-user access
- Remote VM deployment

**For experimentation:** See `../n8n-dev/` (SQLite-based, local development)

## Architecture

**Two-container stack:**
- **n8n** - Workflow automation engine (UID 1000)
- **postgres** - PostgreSQL 16 database (UID 999)

**Networks:**
- `backend_storage` - Traefik access (public)
- `n8n_prod_internal` - Private network for n8n ↔ postgres communication

## UID/GID

- **n8n:** Runs as UID 1000 internally (node user), does NOT respect PUID/PGID
- **PostgreSQL:** Runs as UID 999 internally (postgres user)
- Data directories created as 1000:1000, containers adjust permissions automatically

## Prerequisites

**1. Generate secrets:**
```bash
# PostgreSQL password
openssl rand -base64 32

# n8n encryption key
openssl rand -base64 32
```

**2. Create secrets file:** `/mnt/zpool/Docker/Secrets/n8n-prod.env`
```env
N8N_DB_PASSWORD=<postgres_password_from_above>
N8N_ENCRYPTION_KEY=<encryption_key_from_above>
```

**⚠️ CRITICAL:** Never lose the encryption key - workflow credentials are unrecoverable without it.

## Deployment

**Step 1: Create data directories**
```bash
./build_stack_data.sh
```

**Step 2: Deploy stack**
```bash
cd /mnt/zpool/Docker/Projects/n8n-prod
sudo docker compose up -d
```

**Step 3: Verify deployment**
```bash
# Check PostgreSQL health
sudo docker logs n8n-postgres

# Check n8n startup
sudo docker logs n8n

# Expected: "Editor is now accessible via: https://n8n.a0a0.org"
```

**Step 4: First access**
- Navigate to: https://n8n.a0a0.org
- Create admin account (first user becomes admin)

## Database Management

**PostgreSQL CLI access:**
```bash
sudo docker exec -it n8n-postgres psql -U n8n -d n8n
```

**Common queries:**
```sql
-- List tables
\dt

-- Check workflow count
SELECT COUNT(*) FROM workflow_entity;

-- Check execution count
SELECT COUNT(*) FROM execution_entity;

-- Exit
\q
```

## Backup Strategy

**Manual backup:**
```bash
# Stop containers
cd /mnt/zpool/Docker/Projects/n8n-prod
sudo docker compose down

# Backup both data and database
sudo tar -czf n8n-prod-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  /mnt/zpool/Docker/Stacks/n8n-prod

# Restart containers
sudo docker compose up -d
```

**Database-only backup (no downtime):**
```bash
sudo docker exec n8n-postgres pg_dump -U n8n n8n | \
  gzip > n8n-db-backup-$(date +%Y%m%d-%H%M%S).sql.gz
```

## Restore

**Full restore:**
```bash
# Stop containers
sudo docker compose down

# Remove existing data
sudo rm -rf /mnt/zpool/Docker/Stacks/n8n-prod/*

# Extract backup
sudo tar -xzf n8n-prod-backup-YYYYMMDD-HHMMSS.tar.gz -C /

# Restart containers
sudo docker compose up -d
```

**Database-only restore:**
```bash
# Stop n8n (keep postgres running)
sudo docker stop n8n

# Drop and recreate database
sudo docker exec -it n8n-postgres psql -U n8n -d postgres -c "DROP DATABASE n8n;"
sudo docker exec -it n8n-postgres psql -U n8n -d postgres -c "CREATE DATABASE n8n OWNER n8n;"

# Restore from backup
gunzip -c n8n-db-backup-YYYYMMDD-HHMMSS.sql.gz | \
  sudo docker exec -i n8n-postgres psql -U n8n -d n8n

# Restart n8n
sudo docker start n8n
```

## Troubleshooting

**PostgreSQL not starting:**
```bash
sudo docker logs n8n-postgres
# Check for: permission denied, data directory errors
# Fix: Ensure /mnt/zpool/Docker/Stacks/n8n-prod/postgres exists
```

**n8n can't connect to database:**
```bash
# Check postgres health
sudo docker exec n8n-postgres pg_isready -U n8n -d n8n

# Check network connectivity
sudo docker network inspect n8n_prod_internal
```

**Migrations fail:**
- Usually indicates PostgreSQL not ready when n8n started
- Health check should prevent this, but can manually restart: `sudo docker restart n8n`

## Cleanup

```bash
./remove_data.sh  # Interactive confirmation, deletes ALL data including database
```

## Migration from n8n-dev

**Export from SQLite (n8n-dev):**
1. Access https://n8n-dev.a0a0.org
2. Settings → Import/Export → Export all workflows
3. Save JSON file

**Import to PostgreSQL (n8n-prod):**
1. Access https://n8n.a0a0.org
2. Settings → Import/Export → Import from file
3. Upload JSON from step 3 above

**Note:** Credentials must be re-entered (encryption keys differ between instances).

## Remote VM Deployment

This stack is designed for deployment on a remote VM. Adjust paths as needed:

**Remote paths example:**
```env
DOCKER_ROOT=/opt/docker  # Or your preferred remote path
```

**Remote deployment:**
```bash
# From local workstation, copy files to remote VM
scp -r n8n-prod user@remote-vm:/path/to/docker/projects/

# SSH to remote VM
ssh user@remote-vm
cd /path/to/docker/projects/n8n-prod

# Create secrets file
sudo mkdir -p /opt/docker/Secrets
sudo nano /opt/docker/Secrets/n8n-prod.env
# Add N8N_DB_PASSWORD and N8N_ENCRYPTION_KEY

# Deploy
./build_stack_data.sh
sudo docker compose up -d
```
