# Arcane - Docker Compose Management

**Container management tool (similar to Dockge/Portainer)**

## Current Status

Migrated from TrueNAS Scale app to Docker Compose deployment for consistency with other services.

## Access

- **HTTPS:** https://arcane.a0a0.org (via Traefik)
- **HTTP (direct):** http://192.168.40.6:30258
- **Port:** 30258

## Configuration

**Data directory:** `/mnt/zpool/AppData/arcane-data`
- Contains SQLite database with all stack configurations
- Mounted to `/app/data` in container

**Managed directories:**
- `/mnt/zpool/Docker/Projects` - Compose files (this git repo)
- `/mnt/zpool/Docker/Stacks` - Persistent container data

## Migration from TrueNAS App

### Pre-Migration Checklist

1. **Validate compose file:**
   ```bash
   cd /mnt/truenas-projects/arcane
   docker compose config
   ```

2. **Backup current data (optional but recommended):**
   ```bash
   ssh lavadmin@truenas.a0a0.org
   sudo cp -r /mnt/zpool/AppData/arcane-data /mnt/zpool/AppData/arcane-data.backup
   ```

### Migration Steps

1. **Stop TrueNAS app via GUI:**
   - Navigate to: Apps → arcane → Stop
   - Wait for container to fully stop

2. **Deploy compose version:**
   ```bash
   ssh lavadmin@truenas.a0a0.org
   cd /mnt/zpool/Docker/Projects/arcane
   sudo docker compose up -d
   ```

3. **Verify access:**
   ```bash
   # Check container is running
   sudo docker ps | grep arcane

   # Check health
   curl http://192.168.40.6:30258/api/health
   ```

4. **Test in browser:**
   - Visit: http://192.168.40.6:30258
   - Verify all existing stacks are visible
   - Test starting/stopping a container

5. **If successful, remove TrueNAS app:**
   - Navigate to: Apps → arcane → Delete
   - **Important:** Select "Keep app data" to preserve `/mnt/zpool/AppData/arcane-data`

### Rollback Procedure

If compose deployment fails:

```bash
# Stop compose version
cd /mnt/zpool/Docker/Projects/arcane
sudo docker compose down

# Restart TrueNAS app via GUI
# Navigate to: Apps → arcane → Start
```

Data is preserved in `/mnt/zpool/AppData/arcane-data`, so rollback is safe.

## Common Operations

### Start/Stop
```bash
cd /mnt/zpool/Docker/Projects/arcane
sudo docker compose up -d      # Start
sudo docker compose stop        # Stop
sudo docker compose restart     # Restart
sudo docker compose down        # Stop and remove container
```

### Update to New Version
```bash
cd /mnt/zpool/Docker/Projects/arcane
sudo docker compose pull
sudo docker compose up -d
```

### View Logs
```bash
cd /mnt/zpool/Docker/Projects/arcane
sudo docker compose logs -f
```

### Access Container Shell
```bash
sudo docker exec -it arcane sh
```

## Network Integration

**Traefik Integration:**
- Connected to `backend_storage` network
- HTTPS access via `https://arcane.a0a0.org` with automatic SSL
- Direct HTTP access via `http://192.168.40.6:30258` preserved for backward compatibility

**Note:** Both access methods work simultaneously. Use HTTPS for regular access, HTTP direct for troubleshooting.

## Troubleshooting

### Container won't start
```bash
# Check logs
sudo docker compose logs

# Verify data directory permissions
ls -la /mnt/zpool/AppData/arcane-data
# Should be owned by 568:568 (apps user)
```

### Can't access web interface
```bash
# Verify container is running
sudo docker ps | grep arcane

# Check port binding
sudo netstat -tlnp | grep 30258

# Test local connection
curl http://192.168.40.6:30258/api/health
```

### Database locked errors
```bash
# Another instance might be running
sudo docker ps -a | grep arcane

# Stop all Arcane containers
sudo docker stop $(sudo docker ps -aq --filter "name=arcane")

# Restart compose version
cd /mnt/zpool/Docker/Projects/arcane
sudo docker compose up -d
```

## Notes

- Arcane manages Docker containers via `/var/run/docker.sock` mount
- Runs as user 568:568 (apps user) with docker group permissions
- SQLite database contains all stack configurations - backup regularly
- ENCRYPTION_KEY and JWT_SECRET in `.env` are critical - do not lose!
