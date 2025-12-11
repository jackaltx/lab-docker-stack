# Docker Stack Status Check

Check the status of all Docker services running on the TrueNAS host.

## Instructions

SSH into `truenas.a0a0.org` and perform the following checks:

1. **Container Status**: List all containers with their status
   - Running vs Stopped
   - Uptime
   - Resource usage if available

2. **Health Checks**: For containers with health checks configured
   - Report health status
   - Note any unhealthy containers

3. **Recent Logs**: Check last 50 lines of logs for each service
   - Look for ERROR, WARN, FATAL messages
   - Report any critical issues found

4. **Services to Check**:
   - Traefik (reverse proxy)
   - arr-stack services (gluetun, qbittorrent, sonarr, radarr, readarr, lidarr, prowlarr, bazarr, jellyseerr, flaresolverr, unpackerr, recyclarr, profilarr)
   - Jellyfin
   - Arcane
   - Homarr
   - Dozzle
   - MinIO
   - Gitea
   - FileBrowser
   - FreshRSS
   - Redis
   - 13ft-ladder
   - IT-Tools
   - CyberChef

## Report Format

Generate a concise report with:

```
=== Docker Stack Status Report ===
Generated: [timestamp]
Host: truenas.a0a0.org

SUMMARY:
- Total containers: X
- Running: X
- Stopped: X
- Unhealthy: X

RUNNING SERVICES:
[service name] - [status] - [uptime] - [health if available]

STOPPED SERVICES:
[service name] - [last exit code/reason]

ISSUES FOUND:
[List any errors, warnings, or health problems]

RECENT LOG WARNINGS/ERRORS:
[Service]: [error message excerpt]
```

After generating the report, ask the user if they want to save it to a file (e.g., `status-reports/YYYY-MM-DD-HHmm.md`).

## Notes

- Use `sudo docker` commands on TrueNAS
- Focus on critical issues - don't report normal informational logs
- Keep the report concise and actionable
