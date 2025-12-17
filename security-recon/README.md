# Security Reconnaissance Stack - Passive OSINT

**Purpose:** Passive service detection and fingerprinting from multiple geolocations using VPN-routed containers

**Status:** Manual execution - user-controlled region rotation and tool invocation

---

## Overview

This stack provides lightweight passive reconnaissance tools that route through a VPN (Gluetun) to:
- Test services from different geographic locations
- Detect geo-based service behavior differences
- Practice passive OSINT techniques
- Learn VPN-based container networking patterns

**Key Feature:** All tools share Gluetun's network namespace - traffic appears from VPN IP, not your home IP.

---

## Stack Components

### VPN Gateway
- **Gluetun** - VPN client (Private Internet Access)
- Supports 60+ VPN providers
- Region rotation capability

### Passive Reconnaissance Tools

| Tool | Purpose | Image |
|------|---------|-------|
| **nmap** | Service detection, port scanning | instrumentisto/nmap |
| **whatweb** | Web technology fingerprinting | urbanadventurer/whatweb |
| **sslscan** | TLS/certificate analysis | instrumentisto/nmap (SSL scripts) |
| **dnsrecon** | DNS enumeration | alpine + dnsrecon |
| **theharvester** | OSINT (emails, subdomains) | kurobeats/theharvester |
| **curl** | HTTP headers, redirects | alpine + curl |

---

## Safety First - Passive Scanning Only

**This stack is configured for PASSIVE reconnaissance to avoid triggering fail2ban or IDS/IPS.**

### What Makes Scanning "Passive"?

✅ **Safe (Passive):**
- Service version detection (`nmap -sV`)
- TCP connect scans (`nmap -sT`)
- Polite timing (`nmap -T2`)
- Single HTTP request (`whatweb -a 1`)
- DNS queries (standard lookups)
- Search engine OSINT (theHarvester)
- SSL certificate inspection

❌ **Aggressive (Avoid):**
- SYN scans (`nmap -sS`)
- Fast/aggressive timing (`nmap -T4`, `-T5`)
- Port sweeps (scanning large port ranges rapidly)
- Vulnerability probes with exploits
- Brute force authentication attempts
- Repeated rapid connections

### Safe Nmap Options

```bash
# ✅ SAFE - Use these options
nmap -sT -sV -T2 -p 22,25,80,443,3306,53,8080 target.com

# -sT = TCP connect (completes handshake, logged but not suspicious)
# -sV = Version detection (passive banner grabbing)
# -T2 = Polite timing (slow, 0.4s between probes)
# -p = Specific ports only (not full range)

# ❌ AGGRESSIVE - Avoid these
nmap -sS -T4 -A -p- target.com
# -sS = SYN scan (stealth but detectable)
# -T4 = Aggressive timing (fast, obvious)
# -A = All detection (includes OS detection, scripts)
# -p- = All 65535 ports (very noisy)
```

---

## Initial Setup

### 1. Prerequisites

On TrueNAS:
```bash
ssh lavadmin@truenas.a0a0.org

# Create data directory
sudo mkdir -p /mnt/zpool/Docker/Stacks/security-recon/gluetun
sudo chown -R 568:568 /mnt/zpool/Docker/Stacks/security-recon

# Create VPN credentials file
sudo mkdir -p /mnt/zpool/Docker/Secrets
sudo nano /mnt/zpool/Docker/Secrets/vpn.env
```

**In `/mnt/zpool/Docker/Secrets/vpn.env`:**
```env
OPENVPN_USER=your_pia_username
OPENVPN_PASSWORD=your_pia_password
```

**Secure the secrets file:**
```bash
sudo chmod 600 /mnt/zpool/Docker/Secrets/vpn.env
sudo chown 568:568 /mnt/zpool/Docker/Secrets/vpn.env
```

### 2. Deploy Stack

```bash
cd /mnt/zpool/Docker/Projects/security-recon
sudo docker compose up -d gluetun
```

**Verify VPN connection:**
```bash
# Wait ~30 seconds for VPN to connect
sudo docker logs gluetun-recon | grep "Public IP"

# Should show VPN IP, not your home IP
sudo docker exec gluetun-recon wget -qO- ifconfig.me
```

---

## Manual Testing Workflow

### Phase 1: Test with Safe Target (scanme.nmap.org)

**Nmap's official test server - scanning is explicitly allowed.**

#### 1. Service Detection
```bash
cd /mnt/zpool/Docker/Projects/security-recon
sudo docker compose run --rm nmap \
  -sT -sV -T2 \
  -p 22,25,80,443,3306,53,8080 \
  -oN /results/scanme/nmap-austria.txt \
  scanme.nmap.org
```

**What this does:**
- TCP connect scan (completes full handshake)
- Version detection (grabs service banners)
- Polite timing (slow, respectful)
- Specific ports only
- Saves output to results/scanme/

#### 2. Web Fingerprinting
```bash
sudo docker compose run --rm whatweb \
  -a 1 \
  --log-json=/results/scanme/whatweb-austria.json \
  scanme.nmap.org
```

**What this does:**
- Stealthy mode (-a 1 = single HTTP request)
- Detects web server, CMS, frameworks
- JSON output for easy parsing

#### 3. SSL/TLS Analysis
```bash
sudo docker compose run --rm sslscan \
  -c "nmap -p 443 --script ssl-cert,ssl-enum-ciphers -oN /results/scanme/sslscan-austria.txt scanme.nmap.org"
```

**What this does:**
- Certificate chain inspection
- Supported cipher suites
- Protocol versions (TLS 1.2, 1.3, etc.)

#### 4. DNS Enumeration
```bash
sudo docker compose run --rm dnsrecon \
  -d scanme.nmap.org \
  -t std \
  -o /results/scanme/dnsrecon-austria.txt
```

**What this does:**
- Standard DNS queries (A, AAAA, MX, NS, SOA, TXT)
- No zone transfer attempts
- Safe, passive lookups
- Pre-built image (no installation needed)

#### 5. OSINT via Search Engines
```bash
sudo docker compose run --rm theharvester \
  -d scanme.nmap.org \
  -b google,bing,duckduckgo \
  -f /results/scanme/theharvester-austria
```

**What this does:**
- Searches public search engines only
- Finds emails, subdomains, IPs
- Completely passive (no server contact)

#### 6. HTTP Headers
```bash
sudo docker compose run --rm curl \
  -I -L https://scanme.nmap.org \
  > results/scanme/curl-headers-austria.txt
```

**What this does:**
- Fetches HTTP headers only
- Follows redirects (-L)
- Shows server, cookies, security headers
- Pre-built curl image (no installation needed)

---

## Advanced Reconnaissance with Kali Linux

The Kali container provides 200+ pre-installed security tools to fill gaps left by standalone tool images.

### Tool Coverage Matrix

| Capability | Standalone Service | Kali Alternative | Recommendation |
|------------|-------------------|------------------|----------------|
| Port scanning | nmap ✅ | nmap | Use standalone (lighter) |
| SSL/TLS analysis | sslscan ✅ | testssl.sh | Use standalone |
| DNS enumeration | dnsrecon ✅ | dnsrecon, dnsx | Use standalone |
| HTTP headers | curl ✅ | curl | Use standalone |
| **Web fingerprinting** | whatweb ❌ | **whatweb** ✅ | **Use Kali** |
| **Subdomain discovery** | theharvester ❌ | **subfinder, amass** ✅ | **Use Kali** |
| **Web vulnerability scan** | - | **nikto** ✅ | **Use Kali (passive mode)** |
| Directory brute force | - | gobuster, ffuf, dirb | ⚠️ **Active - use cautiously** |
| SQL injection test | - | sqlmap | ⚠️ **Active - avoid on production** |

### Web Technology Fingerprinting (replaces whatweb)

```bash
sudo docker compose run --rm kali \
  whatweb -a 1 --log-brief=/results/scanme/whatweb-austria.txt \
  scanme.nmap.org
```

**What this does:**
- Identifies web server, CMS, frameworks, JavaScript libraries
- Passive mode (`-a 1`) - single HTTP request only
- Safe for ISPConfig3 detection without triggering fail2ban

### Web Vulnerability Scanning (Passive Mode)

```bash
sudo docker compose run --rm kali \
  nikto -h scanme.nmap.org -Tuning 1 -output /results/scanme/nikto-austria.txt
```

**What this does:**
- Passive checks for common web server misconfigurations
- `-Tuning 1` limits to passive tests only
- Safe when used with caution

**⚠️ WARNING:** Nikto can be aggressive without `-Tuning 1`. Always use passive mode to avoid triggering fail2ban.

### Subdomain Discovery (replaces theharvester)

```bash
sudo docker compose run --rm kali \
  subfinder -d example.com -silent -o /results/scanme/subdomains-austria.txt
```

**What this does:**
- Passive subdomain enumeration using public sources (Certificate Transparency, DNS aggregators)
- No direct DNS queries to target server
- Better coverage than theHarvester
- Completely safe - no server contact

**Alternative:** Use `amass` for more comprehensive results:
```bash
sudo docker compose run --rm kali \
  amass enum -passive -d example.com -o /results/scanme/amass-austria.txt
```

### Directory Enumeration (USE WITH EXTREME CAUTION)

```bash
# ⚠️ ACTIVE SCANNING - Test against scanme.nmap.org ONLY
sudo docker compose run --rm kali \
  gobuster dir -u https://scanme.nmap.org \
  -w /usr/share/wordlists/dirb/common.txt \
  -t 5 --delay 2s -o /results/scanme/gobuster-austria.txt
```

**⚠️ WARNING:** Directory brute forcing is ACTIVE scanning:
- `-t 5` limits threads to 5
- `--delay 2s` adds 2-second delay between requests
- **Will likely trigger fail2ban** if used against protected servers
- **DO NOT use against ISPConfig3 server**
- Test against `scanme.nmap.org` ONLY for learning purposes

### Available Wordlists

Kali includes SecLists and common wordlists:
- `/usr/share/wordlists/dirb/common.txt` - Common directories
- `/usr/share/wordlists/dirbuster/` - Various sized lists
- `/usr/share/wordlists/rockyou.txt.gz` - 15GB password list (compressed)

### List Available Tools

```bash
# List all installed tools
sudo docker compose run --rm kali dpkg -l | grep -E '(whatweb|nikto|subfinder|amass|gobuster)'

# Check if a specific tool is installed
sudo docker compose run --rm kali which whatweb
```

### Safety Guidelines

**✅ Passive/Safe Tools (OK for ISPConfig3):**
- `whatweb -a 1` (stealthy mode)
- `nikto -Tuning 1` (passive checks only)
- `subfinder` (passive subdomain discovery)
- `amass enum -passive` (OSINT mode)
- `testssl.sh` (SSL/TLS analysis)

**❌ Active/Aggressive Tools (AVOID or test on scanme.nmap.org only):**
- `gobuster`/`dirb`/`ffuf` (directory brute force - triggers fail2ban)
- `sqlmap` (SQL injection testing - triggers fail2ban)
- `hydra` (password brute force - triggers fail2ban)
- `nikto` without `-Tuning 1` (aggressive web scanning)
- `wpscan --enumerate` (WordPress brute force)

**Rule of thumb:** If the tool description includes "brute force" or "enumeration" without "passive" - it's likely active scanning.

---

### Phase 2: Rotate Region and Repeat

#### 1. Change VPN Region

**Edit `.env` file:**
```bash
# Change from:
SERVER_REGIONS=Austria

# To:
SERVER_REGIONS=DE Frankfurt
```

#### 2. Restart Gluetun
```bash
sudo docker compose restart gluetun

# Wait for reconnection (~30 seconds)
sudo docker logs gluetun-recon --tail=20 | grep "Public IP"
```

#### 3. Verify New Region
```bash
# Check public IP (should be different from Austria)
sudo docker exec gluetun-recon wget -qO- ifconfig.me

# Optional: Check geolocation
sudo docker exec gluetun-recon wget -qO- ifconfig.co/json
```

#### 4. Run Same Tools, Different Output Files
```bash
# Nmap from Germany
sudo docker compose run --rm nmap \
  -sT -sV -T2 \
  -p 22,25,80,443,3306,53,8080 \
  -oN /results/scanme/nmap-germany.txt \
  scanme.nmap.org

# WhatWeb from Germany
sudo docker compose run --rm whatweb \
  -a 1 \
  --log-json=/results/scanme/whatweb-germany.json \
  scanme.nmap.org

# ... repeat other tools
```

#### 5. Compare Results
```bash
# Compare nmap results
diff /mnt/truenas-projects/security-recon/results/scanme/nmap-austria.txt \
     /mnt/truenas-projects/security-recon/results/scanme/nmap-germany.txt

# Compare whatweb (JSON)
jq '.' results/scanme/whatweb-austria.json > /tmp/austria.json
jq '.' results/scanme/whatweb-germany.json > /tmp/germany.json
diff /tmp/austria.json /tmp/germany.json
```

**What to look for:**
- Different response times (latency)
- Different IP addresses returned
- Geo-specific content (language, CDN servers)
- Blocked/filtered services by region

---

### Phase 3: Test Your Target (ISPConfig3 Server)

⚠️ **Only after validating safe scanning with scanme.nmap.org**

#### 1. Update Target
**Edit `.env` file:**
```bash
# Change:
REAL_TARGET=example.com

# To your actual server:
REAL_TARGET=myserver.example.com
# Or IP address:
REAL_TARGET=203.0.113.10
```

#### 2. Reset to Austria
```bash
# In .env:
SERVER_REGIONS=Austria

# Restart
sudo docker compose restart gluetun
```

#### 3. Run Initial Scan
```bash
# Use your REAL_TARGET variable
sudo docker compose run --rm nmap \
  -sT -sV -T2 \
  -p 22,25,80,443,3306,53,8080,10000 \
  -oN /results/example.com/nmap-austria.txt \
  ${REAL_TARGET}

# Note: Port 10000 is ISPConfig's admin panel
```

#### 4. ISPConfig Fingerprinting

**Web admin panel:**
```bash
sudo docker compose run --rm curl \
  -c "apk add --no-cache curl && curl -I -k https://${REAL_TARGET}:10000 > /results/example.com/ispconfig-headers.txt"
```

**Email banners:**
```bash
sudo docker compose run --rm curl \
  -c "apk add --no-cache curl netcat-openbsd && echo 'QUIT' | nc ${REAL_TARGET} 25 > /results/example.com/smtp-banner.txt"
```

**DNS records:**
```bash
sudo docker compose run --rm dnsrecon \
  -c "apk add --no-cache python3 py3-pip && pip3 install dnsrecon && dnsrecon -d ${REAL_TARGET} -t std > /results/example.com/dns-records.txt"
```

#### 5. Monitor for Bans

**On your ISPConfig3 server, check fail2ban:**
```bash
# Check if VPN IP was banned
sudo fail2ban-client status sshd

# Check fail2ban log
sudo tail -f /var/log/fail2ban.log

# Check auth attempts
sudo tail -f /var/log/auth.log | grep "Failed"
```

**If you get banned:**
- Good learning opportunity!
- Change region in .env → restart Gluetun → new IP
- Verify old IP still banned, new IP works
- Demonstrates fail2ban IP-based blocking

---

## Available Regions

**Common PIA regions for testing:**

| Region | SERVER_REGIONS Value | Use Case |
|--------|---------------------|----------|
| Austria | `Austria` | EU baseline |
| Germany | `DE Frankfurt` or `DE Berlin` | EU primary |
| Spain | `ES Madrid` | Southern EU |
| Estonia | `Estonia` | Northern EU |
| Croatia | `Croatia` | Southeastern EU |
| USA East | `US East` | North America |
| Australia | `Australia` | Asia-Pacific |
| Japan | `Japan` | Asia-Pacific |

**Get full list:**
```bash
sudo docker exec gluetun-recon sh -c "cat /gluetun/servers.json | grep -o '\"region\":\"[^\"]*\"' | sort -u"
```

---

## Results Organization

### Directory Structure

```
results/
├── scanme/                      # Safe test target results
│   ├── nmap-austria.txt
│   ├── nmap-germany.txt
│   ├── nmap-spain.txt
│   ├── whatweb-austria.json
│   ├── whatweb-germany.json
│   ├── sslscan-austria.txt
│   ├── dnsrecon-austria.txt
│   └── theharvester-austria/
│
└── example.com/                 # Your actual target results
    ├── nmap-austria.txt
    ├── nmap-germany.txt
    ├── whatweb-austria.json
    ├── ispconfig-headers.txt
    ├── smtp-banner.txt
    └── dns-records.txt
```

### Manual Organization Tips

**Create region subdirectories:**
```bash
cd results/example.com
mkdir austria germany spain estonia
mv *-austria.* austria/
mv *-germany.* germany/
```

**Add timestamps:**
```bash
# Before running scans, add date to filename
DATE=$(date +%Y%m%d-%H%M)
sudo docker compose run --rm nmap \
  -sT -sV -T2 -p 22,25,80,443 \
  -oN /results/example.com/nmap-austria-${DATE}.txt \
  example.com
```

---

## Troubleshooting

### VPN Won't Connect

```bash
# Check Gluetun logs
sudo docker logs gluetun-recon

# Common issues:
# 1. Wrong credentials in /mnt/zpool/Docker/Secrets/vpn.env
# 2. Invalid region name
# 3. VPN provider issues

# Try different region
# In .env: SERVER_REGIONS=Austria,DE Frankfurt,Spain
# (comma-separated fallbacks)
```

### Tools Can't Reach Internet

```bash
# Verify VPN is connected
sudo docker exec gluetun-recon wget -qO- ifconfig.me

# Test DNS
sudo docker exec gluetun-recon ping -c 2 8.8.8.8
sudo docker exec gluetun-recon ping -c 2 google.com

# If ping fails, check firewall settings in compose.yaml
```

### No Output Files Created

```bash
# Check volume mount permissions
ls -la /mnt/truenas-projects/security-recon/results

# Ensure directory exists and is writable
sudo chown -R 568:568 /mnt/truenas-projects/security-recon/results
```

### "Failed to establish VPN connection"

```bash
# Check VPN credentials
sudo cat /mnt/zpool/Docker/Secrets/vpn.env

# Verify credentials with PIA
# Try different region
# Check Gluetun GitHub issues for provider status
```

---

## Learning Objectives

**By using this stack, you'll learn:**

1. **VPN Container Networking:**
   - Network namespace sharing (`network_mode: service:gluetun`)
   - Traffic routing through VPN
   - Kill switch behavior (if VPN drops, containers lose network)

2. **Passive Reconnaissance:**
   - Difference between passive and aggressive scanning
   - Safe scanning practices to avoid IDS/fail2ban
   - OSINT techniques (search engines, DNS, certificates)

3. **Geo-based Service Behavior:**
   - How services respond differently by region
   - CDN routing and content localization
   - Latency and performance variations

4. **Service Fingerprinting:**
   - Web server detection (Apache, Nginx, ISPConfig)
   - Email server banners (Postfix, Dovecot)
   - DNS server identification (BIND)
   - SSL/TLS configuration analysis

5. **Docker Patterns:**
   - On-demand container execution (`docker compose run --rm`)
   - Shared network namespaces
   - Volume mounts for persistent results
   - Multi-container coordination

---

## Best Practices

### 1. Always Test Safe Targets First
- Use scanme.nmap.org before your own servers
- Verify safe scanning parameters
- Practice workflow before production use

### 2. Respect Rate Limits
- Wait between scans (30+ seconds)
- Use `-T2` timing (polite)
- Don't run parallel scans from same IP

### 3. Coordinate with Server Access
- Monitor fail2ban logs during first tests
- Verify no bans from passive scanning
- Adjust scan parameters if needed

### 4. Document Findings
- Add notes to result files
- Track which region showed different behavior
- Note timing and latency patterns

### 5. Keep VPN Credentials Secure
- Never commit `/mnt/zpool/Docker/Secrets/vpn.env` to git
- Use strong, unique VPN account
- Rotate credentials periodically

---

## Advanced Usage

### Test Multiple Regions Rapidly

**Create a simple loop:**
```bash
#!/bin/bash
REGIONS=("Austria" "DE Frankfurt" "ES Madrid" "Estonia")
TARGET="scanme.nmap.org"

for region in "${REGIONS[@]}"; do
  echo "Testing from $region..."

  # Update .env
  sed -i "s/SERVER_REGIONS=.*/SERVER_REGIONS=$region/" .env

  # Restart Gluetun
  docker compose restart gluetun
  sleep 40  # Wait for VPN reconnection

  # Run nmap
  REGION_SAFE=$(echo $region | tr ' ' '-')
  docker compose run --rm nmap \
    -sT -sV -T2 -p 22,80,443 \
    -oN /results/scanme/nmap-${REGION_SAFE}.txt \
    $TARGET

  echo "$region complete. Waiting 60s before next region..."
  sleep 60
done
```

### Compare Results Programmatically

**Extract specific fields:**
```bash
# Compare open ports across regions
for file in results/scanme/nmap-*.txt; do
  echo "=== $file ==="
  grep "^[0-9]" $file | awk '{print $1,$3}'
done

# Compare SSL ciphers
for file in results/scanme/sslscan-*.txt; do
  echo "=== $file ==="
  grep "TLSv" $file
done
```

---

## References

**Tools:**
- Nmap: https://nmap.org/
- WhatWeb: https://github.com/urbanadventurer/WhatWeb
- theHarvester: https://github.com/laramies/theHarvester
- Gluetun: https://github.com/qdm12/gluetun

**Learning Resources:**
- Nmap Network Scanning: https://nmap.org/book/
- OSINT Framework: https://osintframework.com/
- Safe Scanning Practices: https://nmap.org/book/legal-issues.html

**Related Docs:**
- Gluetun Patterns: See `../docs/gluetun-patterns.md`
- VPN-Torrent Stack: See `../vpn-torrent/`
- arr-stack: See `../arr-stack/`

---

**Last Updated:** 2025-12-17
**Stack Version:** 1.0
**Purpose:** Educational - passive reconnaissance from multiple geolocations
