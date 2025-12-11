# Verify Traefik Routes and Connectivity

Verify all Traefik routes, DNS resolution, SSL certificates, and application connectivity.

## Instructions

Perform comprehensive checks on all services routed through Traefik:

1. **Traefik API/Dashboard Check**:
   - Query Traefik API for all configured routers
   - List all active routes and their backends
   - Check for any routers in error state

2. **DNS Resolution**:
   - Test DNS resolution for all `*.a0a0.org` domains
   - Verify they resolve to 192.168.40.6
   - Report any DNS failures

3. **SSL Certificate Validation**:
   - Check certificate validity for each HTTPS endpoint
   - Report expiration dates
   - Flag any expired or soon-to-expire certs
   - Verify Let's Encrypt issuer

4. **HTTP/HTTPS Connectivity**:
   - Test actual connectivity to each service
   - Verify HTTP redirects to HTTPS
   - Check for 200/301/302 responses (vs 404/500/503)
   - Identify unreachable services

5. **Port Verification**:
   - Compare Traefik loadbalancer.server.port labels with actual container ports
   - Detect port mismatches
   - Check if containers are listening on expected ports

6. **Service Health**:
   - Cross-reference with running containers
   - Identify routes pointing to stopped containers
   - Check for missing route configurations

## Services to Check

All services from CLAUDE.md:
- traefik (docker.a0a0.org)
- homarr (home.a0a0.org)
- dozzle (dozzle.a0a0.org)
- jellyfin (jellyfin.a0a0.org)
- sonarr (sonarr.a0a0.org)
- radarr (radarr.a0a0.org)
- readarr (readarr.a0a0.org)
- lidarr (lidarr.a0a0.org)
- prowlarr (prowlarr.a0a0.org)
- bazarr (bazarr.a0a0.org)
- jellyseerr (jellyseerr.a0a0.org)
- qbittorrent (qbit.a0a0.org)
- minio API (s3-true.a0a0.org)
- minio console (minio-true.a0a0.org)
- gitea (gitea.a0a0.org)
- arcane (arcane.a0a0.org)
- filebrowser (files.a0a0.org)
- freshrss (rss.a0a0.org)
- ladder (ladder.a0a0.org)
- it-tools (it-tools.a0a0.org)
- cyberchef (cyberchef.a0a0.org)

## Commands to Use

```bash
# Query Traefik API for routers
ssh lavadmin@truenas.a0a0.org "curl -s http://192.168.40.6:8080/api/http/routers | jq"

# Test DNS resolution
dig +short sonarr.a0a0.org
dig +short docker.a0a0.org

# Check SSL certificate
echo | openssl s_client -servername sonarr.a0a0.org -connect 192.168.40.6:443 2>/dev/null | openssl x509 -noout -dates -subject

# Test connectivity
curl -sI https://sonarr.a0a0.org
curl -sI http://sonarr.a0a0.org  # Should redirect to HTTPS

# Check container ports
sudo docker port {container_name}

# Get Traefik labels from containers
sudo docker inspect {container} | jq '.[0].Config.Labels'
```

## Report Format

Generate a report with:

```
=== Traefik Routes Verification Report ===
Generated: [timestamp]
Host: truenas.a0a0.org
Traefik Dashboard: https://docker.a0a0.org

SUMMARY:
- Total routes configured: X
- Routes operational: X
- Routes with issues: X
- DNS failures: X
- SSL issues: X
- Connectivity failures: X

OPERATIONAL ROUTES (HTTP 200):
✓ [service] - https://[domain] - Cert expires: YYYY-MM-DD - Backend: [container:port]

ROUTES WITH ISSUES:
⚠ [service] - [domain] - Issue: [description]

DNS RESOLUTION:
✓ [domain] → 192.168.40.6
✗ [domain] → FAILED or wrong IP

SSL CERTIFICATES:
✓ [domain] - Valid until: YYYY-MM-DD (XX days remaining)
⚠ [domain] - Expires soon: YYYY-MM-DD (< 30 days)
✗ [domain] - EXPIRED or invalid

PORT MISMATCHES:
[service]: Traefik expects port XXXX, container listening on YYYY

MISSING ROUTES:
- Running containers without Traefik configuration

ORPHANED ROUTES:
- Traefik routes pointing to stopped/missing containers

DETAILED ISSUES:
[Specific errors, stack traces, or configuration problems]

RECOMMENDATIONS:
- [Action items to fix identified issues]
```

## Output

After generating the report:
1. Display summary to user
2. Ask if they want to save full report to `status-reports/routes-YYYY-MM-DD-HHmm.md`
3. Optionally add critical issues to ISSUES.md

## Notes

- Focus on actionable issues
- Skip verbose output - report problems only
- Use Traefik API when possible (more reliable than parsing logs)
- Test from local workstation for DNS/SSL checks (has better tools)
- SSH to TrueNAS only for Docker-specific checks
