# Filebrowser Stack

Web-based file manager for browsing Docker, Media, and storage share directories.

## Access

**URL:** https://true-browse.a0a0.org

**Initial Admin Credentials:**
- Username: `admin`
- Password: Get from container logs on first startup:
  ```bash
  docker logs filebrowser 2>&1 | grep -i password
  ```

**IMPORTANT:** Change the default password immediately after first login.

## User Management

Filebrowser has its own internal user system - it does NOT use PUID/PGID from the .env file. The `user:` directive in compose.yaml sets the container runtime user but filebrowser manages authentication separately.

## Mounted Directories

Inside filebrowser, you'll see:
- `/config` - Filebrowser configuration
- `/database` - Filebrowser database
- `/srv/Docker` - Browse Docker root directory
- `/srv/Media` - Browse Media directory
- `/srv/storage-nfs` - Browse NFS share
- `/srv/storage-smb` - Browse SMB/Samba share

## Configuration

Edit `.env` file to change:
- `FILEBROWSER_HOST` - Change hostname (requires DNS update)
- `DOCKER_ROOT`, `MEDIA_ROOT`, `ZPOOL_ROOT` - Adjust paths for different deployments
