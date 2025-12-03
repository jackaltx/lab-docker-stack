# Secrets Management Strategy

## Overview

Secrets are stored in a dedicated ZFS dataset, separate from both the git repository and application runtime data.

## Architecture

```
/mnt/zpool/Docker/
├── Projects/     # Git repository (compose files, no secrets)
├── Stacks/       # ZFS Dataset: Application runtime data (snapshots enabled)
└── Secrets/      # ZFS Dataset: Credentials only (snapshots enabled, restricted access)
```

## Dataset Configuration

### Create Secrets Dataset (One-Time Setup)

```bash
ssh lavadmin@truenas.a0a0.org

# Create dataset
sudo zfs create zpool/Docker/Secrets

# Restrict permissions (only lavadmin and root)
sudo chmod 700 /mnt/zpool/Docker/Secrets
sudo chown lavadmin:lavadmin /mnt/zpool/Docker/Secrets

# Optional: Enable encryption
# sudo zfs set encryption=on zpool/Docker/Secrets

# Configure snapshot schedule via TrueNAS GUI
# Recommended: Daily snapshots, 30-day retention
```

### Backup Strategy

- **Stacks dataset**: Contains application state, larger files
- **Secrets dataset**: Contains only .env files, tiny but critical
- **Independent snapshots**: Different retention policies
- **Replication**: Can replicate Secrets to off-site backup separately

## File Structure

Each service with secrets gets a dedicated file in the Secrets dataset:

```
/mnt/zpool/Docker/Secrets/
├── arcane.env       # Arcane encryption/JWT keys
├── traefik.env      # Linode DNS token ONLY (see note below)
├── minio.env        # S3 root credentials
├── arr-stack.env    # VPN credentials
└── homarr.env       # Dashboard encryption key
```

**Special Case - Traefik:**

- `USER_PASSWD` (dashboard password hash) remains in git-tracked `traefik3/.env`
- Required for label substitution at Docker Compose parse-time
- `env_file:` loads variables AFTER labels are parsed
- Bcrypt hash is relatively safe to expose (computationally expensive to crack)
- TODO: Move to Traefik config file or Ansible template for better security

## Docker Compose Pattern

### Standard Template

```yaml
services:
  service-name:
    image: organization/image:tag
    container_name: service-name

    # Load non-sensitive config from git-tracked .env
    # Load secrets from Secrets dataset
    env_file:
      - .env                                      # PUID/PGID/TZ/etc (committed to git)
      - /mnt/zpool/Docker/Secrets/service.env    # Secrets only (never in git)

    volumes:
      - /mnt/zpool/Docker/Stacks/service:/config  # App data

    networks:
      - backend_storage
    restart: unless-stopped
```

### What Goes Where

**In git-tracked `.env` (Projects directory):**

```env
# Safe to commit
PUID=568
PGID=568
TZ=America/Chicago
PORT=8080
ENVIRONMENT=production
```

**In Secrets dataset `.env` (Secrets directory):**

```env
# NEVER commit these
API_TOKEN=secret_key_here
DATABASE_PASSWORD=secure_password
ENCRYPTION_KEY=random_string
JWT_SECRET=another_random_string
```

## Security Benefits

### Isolation

- Secrets not mixed with application data
- Corruption in Stacks dataset doesn't affect credentials
- Can restore app data without exposing secrets

### Access Control

- Dataset-level permissions (700)
- Not accessible via NFS mount (Projects is NFS)
- Only accessible via direct TrueNAS access

### Audit Trail

- ZFS snapshots track every change with timestamps
- Easy to rollback bad secret rotations
- Snapshot diff shows what changed

### Backup/Restore

- Smaller backup footprint (text files only)
- Faster restore operations
- Can replicate to off-site storage independently

## Migration from Committed Secrets

For each service currently with secrets in git:

1. **Extract secrets to new file:**

   ```bash
   ssh lavadmin@truenas.a0a0.org
   sudo nano /mnt/zpool/Docker/Secrets/service.env
   # Paste secret variables only
   ```

2. **Update compose file:**

   ```yaml
   env_file:
     - .env
     - /mnt/zpool/Docker/Secrets/service.env
   ```

3. **Remove secrets from git-tracked .env:**

   ```bash
   # Keep only PUID/PGID/TZ and non-sensitive vars
   vim service/.env
   git add service/.env
   git commit -m "Remove secrets from service .env"
   ```

4. **Test deployment:**

   ```bash
   ssh lavadmin@truenas.a0a0.org
   cd /mnt/zpool/Docker/Projects/service
   sudo docker compose down
   sudo docker compose up -d
   # Verify service works with split env files
   ```

5. **Rotate exposed credentials:**
   - Generate new secrets
   - Update in Secrets dataset
   - Restart service
   - Verify functionality

## Credential Rotation Workflow

```bash
# Snapshot before rotation
ssh lavadmin@truenas.a0a0.org
sudo zfs snapshot zpool/Docker/Secrets@pre-rotation-$(date +%Y%m%d)

# Edit secrets
sudo nano /mnt/zpool/Docker/Secrets/service.env

# Restart service
cd /mnt/zpool/Docker/Projects/service
sudo docker compose restart

# Test service functionality
# If problems: sudo zfs rollback zpool/Docker/Secrets@pre-rotation-YYYYMMDD
```

## Git Repository Rules

### .gitignore

```gitignore
.claude/
**/.env.local
**/.env.secrets
**/secrets/
```

### What to Commit

**DO commit:**

- `compose.yaml` files with `env_file:` directives
- `.env` files with ONLY non-sensitive variables (PUID/PGID/TZ)
- `.env.example` templates showing required variables

**NEVER commit:**

- API tokens
- Passwords
- Encryption keys
- VPN credentials
- Any file from `/mnt/zpool/Docker/Secrets/`

## Services Requiring Secret Files

| Service | Secrets File | Contents |
|---------|-------------|----------|
| traefik3 | `/mnt/zpool/Docker/Secrets/traefik.env` | LINODE_TOKEN (USER_PASSWD in git-tracked .env) |
| arr-stack | `/mnt/zpool/Docker/Secrets/arr-stack.env` | OPENVPN_USER, OPENVPN_PASSWORD |
| minio | `/mnt/zpool/Docker/Secrets/minio.env` | MINIO_ROOT_USER, MINIO_ROOT_PASSWORD |
| homarr | `/mnt/zpool/Docker/Secrets/homarr.env` | SECRET_ENCRYPTION_KEY |
| arcane | `/mnt/zpool/Docker/Secrets/arcane.env` | ENCRYPTION_KEY, JWT_SECRET |

## Disaster Recovery

### Backup Priority

1. **Critical**: Secrets dataset (credentials)
2. **Important**: Stacks dataset (app state)
3. **Optional**: Projects directory (git handles this)

### Recovery Scenarios

**Scenario 1: Lost all Docker data**

```bash
# Restore Secrets dataset from backup
zfs receive zpool/Docker/Secrets < backup.zfs

# Restore Stacks dataset from backup
zfs receive zpool/Docker/Stacks < backup.zfs

# Clone git repo
cd /mnt/zpool/Docker
git clone https://github.com/jackaltx/llab-docker-stack.git Projects

# Deploy services
cd Projects/arcane
sudo docker compose up -d
```

**Scenario 2: Secrets compromised**

```bash
# Rollback to last known good snapshot
sudo zfs rollback zpool/Docker/Secrets@known-good-snapshot

# Or rotate all credentials manually
# Create new credentials
# Update Secrets dataset
# Restart all services
```

## Future Enhancements

- **Secrets encryption**: Enable ZFS native encryption on dataset
- **Secret rotation automation**: Ansible playbook to rotate credentials
- **Audit logging**: Track all access to Secrets directory
- **Off-site replication**: Automated sync to backup location
