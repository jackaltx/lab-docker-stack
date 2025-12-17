# Gluetun VPN Container Pattern - Use Cases & Implementation Guide

## Overview

**Gluetun** is a lightweight VPN client container that enables routing other Docker containers through a VPN connection. This pattern is powerful for privacy, security testing, geo-distributed testing, and learning about container networking.

**Repository:** https://github.com/qdm12/gluetun

**Key Feature:** Network namespace sharing via `network_mode: service:gluetun`

---

## How It Works

### Network Namespace Sharing

When a container uses `network_mode: service:gluetun`, it shares Gluetun's entire network stack:

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=private internet access
      - SERVER_REGIONS=Austria
    # Ports exposed HERE (not on dependent containers)
    ports:
      - "8080:8080"

  app:
    image: some/application
    network_mode: "service:gluetun"  # <-- Shares Gluetun's network
    # NO ports: section here - use Gluetun's ports
```

**What this means:**
- `app` container uses Gluetun's network interface
- All traffic from `app` goes through VPN tunnel
- If VPN drops, `app` loses network connectivity (built-in kill switch)
- Other containers reach `app` via `gluetun:8080` hostname

---

## Use Cases by Category

### 1. Privacy & Anonymity

#### Web Scraping / Data Collection
```yaml
services:
  gluetun:
    # VPN configuration

  scrapy:
    image: scrapy/scrapy
    network_mode: service:gluetun
    volumes:
      - ./scraper:/scraper
```

**Why:** Rotate IP addresses, bypass rate limits, avoid geo-blocking

**Learning:** How web services track and block by IP

---

#### Privacy-Focused Browsers
```yaml
firefox:
  image: linuxserver/firefox
  network_mode: service:gluetun
  environment:
    - PUID=1000
    - PGID=1000
```

**Why:** Browse through VPN without local VPN client, disposable sessions

**Learning:** Browser fingerprinting, VPN detection techniques

---

#### HTTP/SOCKS Proxy Services
```yaml
privoxy:
  image: vimagick/privoxy
  network_mode: service:gluetun
```

**Why:** Create your own VPN-backed proxy for other devices/apps

**Learning:** Proxy protocols, traffic forwarding

---

### 2. Security Testing & OSINT

#### Passive Reconnaissance
```yaml
services:
  gluetun:
    environment:
      - SERVER_REGIONS=Austria,Germany,Spain

  nmap:
    image: instrumentisto/nmap
    network_mode: service:gluetun
    volumes:
      - ./results:/results

  theharvester:
    image: kurobeats/theharvester
    network_mode: service:gluetun
```

**Why:** Service detection from different geolocations, avoid source IP tracking

**Learning:** Passive vs active scanning, geo-based service responses

**Real Example:** See `security-recon/` stack in this repository

---

#### Penetration Testing
```yaml
kali:
  image: kalilinux/kali-rolling
  network_mode: service:gluetun
```

**Why:** Source traffic from different regions, anonymize security assessments

**Learning:** Attack attribution, IDS/IPS detection patterns

⚠️ **Warning:** Only test systems you own or have explicit permission to test

---

#### Vulnerability Scanning
```yaml
nuclei:
  image: projectdiscovery/nuclei
  network_mode: service:gluetun
```

**Why:** Avoid IP bans during scanning, test geo-specific vulnerabilities

**Learning:** Rate limiting, detection avoidance

---

### 3. Development & Testing

#### API Testing from Different Regions
```yaml
newman:
  image: postman/newman
  network_mode: service:gluetun
  volumes:
    - ./collections:/collections
```

**Why:** Verify API geo-restrictions, test CDN behavior

**Learning:** Geographic load balancing, content localization

---

#### Continuous Integration with VPN
```yaml
gitlab-runner:
  image: gitlab/gitlab-runner
  network_mode: service:gluetun
```

**Why:** Run CI jobs through VPN (testing VPN-dependent features)

**Learning:** CI/CD networking, service dependency management

---

#### Multi-Region Load Testing
```yaml
# Deploy multiple Gluetun instances
gluetun-us:
  environment:
    - SERVER_REGIONS=US East

gluetun-eu:
  environment:
    - SERVER_REGIONS=DE Frankfurt

locust-us:
  image: locustio/locust
  network_mode: service:gluetun-us

locust-eu:
  image: locustio/locust
  network_mode: service:gluetun-eu
```

**Why:** Simulate distributed user base, test geo-failover

**Learning:** Load distribution, latency patterns

---

### 4. Media & Content

#### Torrent Clients (with VPN Kill Switch)
```yaml
services:
  gluetun:
    ports:
      - "8085:8085"

  qbittorrent:
    image: linuxserver/qbittorrent
    network_mode: service:gluetun
    volumes:
      - ./config:/config
      - ./downloads:/downloads
```

**Why:** Privacy, ISP throttling bypass, built-in kill switch

**Learning:** P2P protocols, VPN leak prevention

**Real Example:** See `arr-stack/` and `vpn-torrent/` stacks in this repository

---

#### YouTube Downloaders
```yaml
yt-dlp:
  image: jauderho/yt-dlp
  network_mode: service:gluetun
```

**Why:** Bypass throttling, access geo-restricted content

**Learning:** Content delivery networks, geo-blocking

---

#### Streaming Services
```yaml
streamlink:
  image: ghcr.io/streamlink/streamlink
  network_mode: service:gluetun
```

**Why:** Route streaming through different regions

**Learning:** DRM, geo-fencing techniques

---

### 5. Monitoring & Research

#### RSS Feed Aggregators
```yaml
freshrss:
  image: linuxserver/freshrss
  network_mode: service:gluetun
```

**Why:** Hide which feeds you monitor, bypass paywalls

**Learning:** Content syndication, privacy implications

---

#### OSINT Tools
```yaml
# Domain intelligence
amass:
  image: caffix/amass
  network_mode: service:gluetun

# Subdomain discovery
subfinder:
  image: projectdiscovery/subfinder
  network_mode: service:gluetun
```

**Why:** Anonymize reconnaissance, distribute queries across IPs

**Learning:** DNS enumeration, passive information gathering

---

#### Price Monitoring / Market Research
```yaml
price-tracker:
  image: custom-scraper
  network_mode: service:gluetun
```

**Why:** Check prices from different regions, avoid detection

**Learning:** Dynamic pricing, geo-based price discrimination

---

### 6. Communication

#### IRC / Matrix Clients
```yaml
weechat:
  image: weechat/weechat
  network_mode: service:gluetun
```

**Why:** Anonymize chat connections, avoid network-based bans

**Learning:** IRC protocols, connection fingerprinting

---

#### Email Clients (Temporary Use)
```yaml
thunderbird:
  image: linuxserver/thunderbird
  network_mode: service:gluetun
```

**Why:** Access email from restricted networks, temporary privacy

**Learning:** SMTP/IMAP protocols, email security

---

## Multi-Region Pattern

Deploy multiple Gluetun instances for geo-distributed testing:

```yaml
services:
  # USA Gateway
  gluetun-us:
    image: qmcgaw/gluetun
    container_name: gluetun-us
    environment:
      - VPN_SERVICE_PROVIDER=private internet access
      - SERVER_REGIONS=US East
      - OPENVPN_USER=${VPN_USER}
      - OPENVPN_PASSWORD=${VPN_PASS}
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun

  # Europe Gateway
  gluetun-eu:
    image: qmcgaw/gluetun
    container_name: gluetun-eu
    environment:
      - VPN_SERVICE_PROVIDER=private internet access
      - SERVER_REGIONS=DE Frankfurt
      - OPENVPN_USER=${VPN_USER}
      - OPENVPN_PASSWORD=${VPN_PASS}
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun

  # Asia Gateway
  gluetun-apac:
    image: qmcgaw/gluetun
    container_name: gluetun-apac
    environment:
      - VPN_SERVICE_PROVIDER=private internet access
      - SERVER_REGIONS=Australia
      - OPENVPN_USER=${VPN_USER}
      - OPENVPN_PASSWORD=${VPN_PASS}
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun

  # Route different tools through different regions
  tool-us:
    image: some/tool
    network_mode: service:gluetun-us

  tool-eu:
    image: some/tool
    network_mode: service:gluetun-eu

  tool-apac:
    image: some/tool
    network_mode: service:gluetun-apac
```

**Use cases:**
- Compare service responses across regions
- Distributed security scanning
- Multi-region monitoring
- Load testing with geographic distribution

---

## Key Configuration Options

### Supported VPN Providers

Gluetun supports 60+ VPN providers including:
- Private Internet Access (PIA)
- NordVPN
- Mullvad
- ProtonVPN
- Surfshark
- ExpressVPN
- Custom OpenVPN/Wireguard configs

### Important Environment Variables

```yaml
environment:
  # VPN Provider
  - VPN_SERVICE_PROVIDER=private internet access
  - VPN_TYPE=openvpn  # or wireguard

  # Authentication
  - OPENVPN_USER=${VPN_USER}
  - OPENVPN_PASSWORD=${VPN_PASS}

  # Region Selection
  - SERVER_REGIONS=Austria,Germany,Spain  # Comma-separated
  - SERVER_CITIES=Vienna,Frankfurt        # More specific

  # Port Forwarding (for torrents)
  - VPN_PORT_FORWARDING=on
  - VPN_PORT_FORWARDING_PROVIDER=private internet access

  # DNS Configuration
  - DNS_ADDRESS=9.9.9.9  # Quad9, or 8.8.8.8, 1.1.1.1

  # Firewall (allow Docker network through VPN)
  - FIREWALL_OUTBOUND_SUBNETS=172.20.43.0/24

  # IPv6
  - BLOCK_IPV6=on  # Prevent IPv6 leaks

  # Health Check
  - HEALTH_VPN_DURATION_INITIAL=30s
```

### Port Exposure

**Critical:** Ports MUST be exposed on Gluetun, not the dependent container:

```yaml
# ✅ CORRECT
gluetun:
  ports:
    - "8080:8080"

app:
  network_mode: service:gluetun
  # NO ports: section

# ❌ WRONG
gluetun:
  # No ports

app:
  network_mode: service:gluetun
  ports:
    - "8080:8080"  # This won't work!
```

---

## Traefik Integration

If using Traefik reverse proxy, labels go on Gluetun:

```yaml
gluetun:
  image: qmcgaw/gluetun
  networks:
    - backend_media
  ports:
    - "8085:8085"
  labels:
    - "traefik.enable=true"
    - "traefik.docker.network=backend_media"
    - "traefik.http.routers.app.rule=Host(`app.example.com`)"
    - "traefik.http.routers.app.entrypoints=websecure"
    - "traefik.http.routers.app.tls.certresolver=letsencrypt"
    - "traefik.http.services.app.loadbalancer.server.port=8085"

app:
  network_mode: service:gluetun
  # Traefik routes to gluetun:8085
```

---

## VPN Leak Testing

Always verify traffic routes through VPN:

```bash
# Check container's public IP
docker exec gluetun curl ifconfig.me
docker exec app curl ifconfig.me

# Should match Gluetun's VPN IP, not your home IP

# Test kill switch (stop Gluetun, verify app loses connectivity)
docker stop gluetun
docker exec app curl ifconfig.me  # Should fail
```

---

## Common Patterns & Tips

### 1. Conditional Services (Docker Profiles)

Run tools only when needed:

```yaml
services:
  gluetun:
    # Always running

  nmap:
    network_mode: service:gluetun
    profiles: ["security"]  # Start only with --profile security

  nuclei:
    network_mode: service:gluetun
    profiles: ["security"]
```

**Usage:**
```bash
# Normal: Just VPN
docker compose up -d

# Security testing: Add tools
docker compose --profile security up -d
```

---

### 2. On-Demand Tool Execution

Run tools without keeping containers running:

```yaml
services:
  gluetun:
    # Persistent VPN gateway

  nmap:
    image: instrumentisto/nmap
    network_mode: service:gluetun
    # No restart: or depends_on
```

**Usage:**
```bash
# Start VPN
docker compose up -d gluetun

# Run tool on-demand
docker compose run --rm nmap -sV scanme.nmap.org

# Gluetun stays running, nmap container removed after use
```

---

### 3. Lightweight Alpine + Tools

Minimal container with tools installed on-demand:

```yaml
alpine-tools:
  image: alpine:latest
  network_mode: service:gluetun
  command: sleep infinity
```

**Usage:**
```bash
# Install tools as needed
docker exec alpine-tools apk add nmap curl bind-tools

# Run commands
docker exec alpine-tools nmap -sV example.com
docker exec alpine-tools dig @8.8.8.8 example.com
```

**Size:** 7MB base + ~20MB tools = 27MB total

---

## Learning Lab Value

### What You Learn

1. **Container Networking:**
   - Network namespaces
   - Bridge networks
   - Inter-container communication
   - DNS resolution in Docker

2. **VPN Technology:**
   - OpenVPN vs WireGuard
   - Kill switch mechanics
   - DNS leak prevention
   - Port forwarding

3. **Security Concepts:**
   - Traffic isolation
   - IP attribution
   - Geo-blocking mechanisms
   - IDS/IPS detection

4. **Service Architecture:**
   - Dependency management
   - Service discovery
   - Reverse proxy patterns
   - Health checking

5. **Troubleshooting:**
   - Network debugging with tcpdump
   - Connection tracing
   - Log analysis
   - Container introspection

### Hands-On Exercises

1. **VPN Kill Switch Test:**
   - Start Gluetun + app
   - Check app's public IP
   - Stop Gluetun
   - Verify app loses connectivity

2. **Multi-Region Comparison:**
   - Deploy 3 Gluetun instances (US, EU, APAC)
   - Run same nmap scan from each
   - Compare results: timing, responses, service behavior

3. **Traffic Capture:**
   - Use tcpdump on Docker bridge
   - Monitor VPN tunnel traffic
   - Verify encryption (no plaintext)

4. **Traefik Routing:**
   - Route service through Gluetun
   - Configure Traefik labels
   - Test SSL termination
   - Monitor access logs

---

## Real-World Examples in This Repository

### 1. arr-stack (Media Automation)
**Location:** `/mnt/truenas-projects/arr-stack/`

**Pattern:** Gluetun + qBittorrent with network namespace sharing

**Purpose:** Torrent traffic routed through VPN, all other services direct

**Learn:** Selective VPN routing, kill switch, port forwarding

---

### 2. vpn-torrent (Standalone Torrent)
**Location:** `/mnt/truenas-projects/vpn-torrent/`

**Pattern:** Minimal Gluetun + qBittorrent stack

**Purpose:** Simplified extraction from arr-stack for learning

**Learn:** Basic VPN container pattern, decoupling services

---

### 3. security-recon (Passive Reconnaissance)
**Location:** `/mnt/truenas-projects/security-recon/`

**Pattern:** Gluetun + multiple passive OSINT tools

**Purpose:** Service fingerprinting from different geolocations

**Learn:** Multi-region testing, passive scanning, safe reconnaissance

---

## Troubleshooting

### Container Can't Connect to Internet

```bash
# Check Gluetun VPN status
docker logs gluetun | grep "Public IP"

# Verify DNS
docker exec gluetun ping -c 2 8.8.8.8

# Check firewall rules
docker exec gluetun iptables -L -n
```

### "Permission denied" on /dev/net/tun

Add capabilities:
```yaml
gluetun:
  cap_add:
    - NET_ADMIN
  devices:
    - /dev/net/tun:/dev/net/tun
```

### VPN Keeps Disconnecting

- Check VPN provider status
- Try different region: `SERVER_REGIONS=Austria,Germany` (comma-separated fallbacks)
- Increase health check duration: `HEALTH_VPN_DURATION_INITIAL=60s`

### Can't Reach Container from Other Services

- Ensure firewall allows Docker network: `FIREWALL_OUTBOUND_SUBNETS=172.20.0.0/16`
- Check Gluetun is on same Docker network
- Use `gluetun:PORT` as hostname, not container name

---

## Security Considerations

### Do's
✅ Use VPN for privacy-sensitive tasks
✅ Verify VPN connection before transmitting data
✅ Test kill switch regularly
✅ Use DNS from VPN provider or trusted resolver
✅ Block IPv6 to prevent leaks
✅ Monitor VPN connection health

### Don'ts
❌ Trust VPN alone for anonymity (consider Tor for high threat)
❌ Expose VPN credentials in Git (use secrets management)
❌ Run untrusted code through VPN (lateral movement risk)
❌ Assume VPN hides all metadata (timing analysis still possible)
❌ Use free VPN providers (privacy/security risks)

---

## References

**Gluetun Documentation:**
- GitHub: https://github.com/qdm12/gluetun
- Wiki: https://github.com/qdm12/gluetun/wiki
- Supported Providers: https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers

**Related Projects:**
- Docker Networking: https://docs.docker.com/network/
- Traefik Reverse Proxy: https://doc.traefik.io/traefik/
- Private Internet Access: https://www.privateinternetaccess.com/

**Learning Resources:**
- Docker Network Namespaces: https://man7.org/linux/man-pages/man7/network_namespaces.7.html
- OpenVPN: https://openvpn.net/community-resources/
- WireGuard: https://www.wireguard.com/

---

**Last Updated:** 2025-12-17
**Repository:** https://github.com/jackaltx/true-lab-docker-stack
**Related:** See `security-recon/` and `vpn-torrent/` stacks for working examples
