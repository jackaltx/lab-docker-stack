# Network Traffic Capture - backend_media Docker Bridge

## Quick Reference

**Bridge Interface:** `br-9ea2b7ca09dc`
**Network Name:** `backend_media`
**Network ID:** `9ea2b7ca09dc5320d5e6a02efe1a46a98d5aea137701e3d8122d36df5e7c855c`

---

## Basic Capture Commands

### 1. Live Traffic Viewing
```bash
ssh lavadmin@truenas.a0a0.org
sudo tcpdump -i br-9ea2b7ca09dc -n
```

### 2. Capture to File (Wireshark Analysis)
```bash
# On TrueNAS
sudo tcpdump -i br-9ea2b7ca09dc -w /tmp/backend_media_capture.pcap

# Download to local machine
scp lavadmin@truenas.a0a0.org:/tmp/backend_media_capture.pcap .
```

### 3. HTTP/HTTPS Traffic Only
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n 'tcp port 80 or tcp port 443 or tcp port 8080'
```

### 4. Specific Service (Example: Sonarr)
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n 'port 8989'
```

### 5. Detailed Packet Contents (Hex/ASCII)
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n -X
```

### 6. Filter by Container IP
```bash
# Find container IP first
sudo docker inspect sonarr | grep IPAddress

# Capture traffic to/from that IP
sudo tcpdump -i br-9ea2b7ca09dc -n 'host 172.20.43.X'
```

---

## Useful Filters

### DNS Queries
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n 'port 53'
```

### Between Two Services (e.g., Sonarr → Prowlarr)
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n 'host sonarr and host prowlarr'
```

### Exclude Traefik Health Checks
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n 'not port 80 and not port 443'
```

### All arr Stack Traffic (Exclude Other Services)
```bash
# Get arr stack container IPs
sudo docker network inspect backend_media | jq -r '.Containers[] | select(.Name | contains("arr") or contains("qbit") or contains("gluetun") or contains("prowlarr") or contains("bazarr") or contains("jellyseerr")) | .IPv4Address'

# Use those IPs in filter
sudo tcpdump -i br-9ea2b7ca09dc -n 'host 172.20.43.X or host 172.20.43.Y or host 172.20.43.Z'
```

---

## Capture Inside a Container

Install tcpdump in a running container:
```bash
# LinuxServer.io images use Alpine
sudo docker exec -it sonarr sh -c "apk add --no-cache tcpdump && tcpdump -n"

# Debian-based containers
sudo docker exec -it container_name bash -c "apt-get update && apt-get install -y tcpdump && tcpdump -n"
```

---

## Advanced: tcpdump Options

| Option | Purpose |
|--------|---------|
| `-i <interface>` | Interface to capture on |
| `-n` | Don't resolve hostnames (faster) |
| `-nn` | Don't resolve hostnames or port names |
| `-X` | Show packet contents in hex and ASCII |
| `-v`, `-vv`, `-vvv` | Verbose output (more detail) |
| `-w <file>` | Write raw packets to file |
| `-r <file>` | Read packets from file |
| `-c <count>` | Capture only N packets then stop |
| `-s <snaplen>` | Bytes to capture per packet (0 = unlimited) |
| `-A` | Print packets in ASCII |

---

## Common Use Cases

### Troubleshoot Prowlarr → Sonarr Communication
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n -A 'port 8989'
```

### Verify VPN Routing (qBittorrent)
```bash
# qBittorrent uses Gluetun's network stack
sudo docker inspect gluetun | grep IPAddress
sudo tcpdump -i br-9ea2b7ca09dc -n 'host <gluetun_ip> and not port 8085'
```

### Monitor Jellyseerr API Calls
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n -A 'port 5055 and host jellyseerr'
```

### Capture All Indexer Traffic (Prowlarr)
```bash
sudo tcpdump -i br-9ea2b7ca09dc -n 'port 9696'
```

---

## Mirror Port Equivalent (Port Mirroring)

**Q: Is there a "mirror port" concept on virtual bridges?**

**A:** Linux bridges don't have traditional SPAN/mirror port functionality like physical switches, but you can achieve similar results:

### Option 1: tcpdump on Bridge (What We're Doing)
- **Method:** Capture directly on bridge interface
- **Pros:** Simple, works immediately, no configuration
- **Cons:** Must run tcpdump on host, CPU overhead
- **Use Case:** Temporary troubleshooting, ad-hoc analysis

### Option 2: Linux tc (Traffic Control) - Mirror to Interface
```bash
# Mirror all traffic from br-9ea2b7ca09dc to another interface
sudo tc qdisc add dev br-9ea2b7ca09dc ingress
sudo tc filter add dev br-9ea2b7ca09dc parent ffff: \
  protocol all u32 match u8 0 0 \
  action mirred egress mirror dev <target_interface>
```
- **Pros:** Mirrors traffic to another interface (could be virtual for monitoring tool)
- **Cons:** Complex setup, requires target interface
- **Use Case:** Continuous monitoring, send to IDS/IPS

### Option 3: ebtables - Bridge Firewall with Logging
```bash
# Log all traffic passing through bridge
sudo ebtables -A FORWARD -j log --log-level info --log-prefix "BRIDGE: "
# View in: dmesg or /var/log/kern.log
```
- **Pros:** Kernel-level logging
- **Cons:** Limited detail, fills logs quickly
- **Use Case:** High-level traffic pattern analysis

### Option 4: Custom Network Namespace with veth Pair
Create a "tap" into the network by inserting a virtual interface:
```bash
# Advanced - creates virtual "wire tap" between containers
# Requires recreating container network configs
```
- **Pros:** True "mirror port" behavior
- **Cons:** Complex, requires network reconfiguration
- **Use Case:** Permanent monitoring infrastructure

### Option 5: Container with Network Mode = Container
```bash
# Run monitoring container sharing another container's network
sudo docker run --network=container:sonarr nicolaka/netshoot tcpdump -i eth0
```
- **Pros:** See traffic from specific container's perspective
- **Cons:** Only sees one container's view
- **Use Case:** Debug specific container networking

---

## Recommendation

**For Docker bridge troubleshooting:**
Use **tcpdump on the bridge interface** (Option 1) - it's the Linux equivalent of configuring a SPAN port and plugging in a laptop with Wireshark.

**Why traditional mirror ports don't exist in Linux bridges:**
- Linux bridges operate at kernel level with direct packet access
- No need for "mirroring" when you can capture directly
- Physical switches mirror because you can't "tap into" backplane
- Virtual networking lets you capture anywhere in the stack

**Best practices:**
1. Use `tcpdump` on bridge for live troubleshooting
2. Save pcap files for offline analysis in Wireshark
3. Filter early (at capture time) to reduce noise
4. Use container-specific captures when debugging single service

---

## Finding Container IPs for Filtering

```bash
# All containers on backend_media
sudo docker network inspect backend_media | jq -r '.Containers[] | "\(.Name): \(.IPv4Address)"'

# Specific container
sudo docker inspect sonarr --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

---

**Created:** 2025-12-03
**Network:** backend_media (arr-stack)
**TrueNAS IP:** 192.168.40.6
