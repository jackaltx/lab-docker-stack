# Network Performance Testing & Diagnosis

**Purpose:** Diagnose network performance issues - identify whether slowness is from VPN, ISP, or local network

**Last Updated:** 2025-12-03

---

## Quick Diagnosis Commands

### 1. Host Network Speed (Direct ISP Connection)
```bash
ssh lavadmin@truenas.a0a0.org
curl -o /dev/null -s -w 'Downloaded: %{size_download} bytes\nSpeed: %{speed_download} bytes/sec (%.2f MB/sec)\nTime: %{time_total}s\n' --max-time 30 https://proof.ovh.net/files/10Mb.dat
```

**What it tests:** TrueNAS host → Internet via your ISP (no VPN)

### 2. VPN Speed (Through Gluetun)
```bash
ssh lavadmin@truenas.a0a0.org
sudo docker exec qbittorrent curl -o /dev/null -s -w 'Downloaded: %{size_download} bytes\nSpeed: %{speed_download} bytes/sec (%.2f MB/sec)\nTime: %{time_total}s\n' --max-time 30 https://proof.ovh.net/files/10Mb.dat
```

**What it tests:** qBittorrent container → Internet via Gluetun VPN tunnel

### 3. Container Network Speed (No VPN)
```bash
ssh lavadmin@truenas.a0a0.org
sudo docker exec sonarr curl -o /dev/null -s -w 'Downloaded: %{size_download} bytes\nSpeed: %{speed_download} bytes/sec (%.2f MB/sec)\nTime: %{time_total}s\n' --max-time 30 https://proof.ovh.net/files/10Mb.dat
```

**What it tests:** Regular container → Internet via Docker bridge → Host → ISP

### 4. Verify IP Addresses
```bash
ssh lavadmin@truenas.a0a0.org
echo "Host IP:" && curl -s ifconfig.me
echo "VPN IP (qBittorrent):" && sudo docker exec qbittorrent curl -s ifconfig.me
echo "Sonarr IP:" && sudo docker exec sonarr curl -s ifconfig.me
```

**Expected results:**
- Host and Sonarr: Your home IP address
- qBittorrent: VPN provider IP (e.g., Italy for PIA)

### 5. Container-to-Container Speed
```bash
ssh lavadmin@truenas.a0a0.org
time sudo docker exec sonarr curl -o /dev/null -s http://prowlarr:9696
```

**What it tests:** Internal Docker network performance (should be < 1 second)

---

## Interpreting Results

### Speed Conversion
```
1 MB/sec = 1,000,000 bytes/sec = 8 Mbps (megabits per second)
100 KB/sec = 100,000 bytes/sec = 0.8 Mbps
```

### Typical Speeds
| Connection Type | Expected Speed | In bytes/sec |
|----------------|----------------|--------------|
| **Gigabit LAN** | 1000 Mbps | ~125,000,000 bytes/sec |
| **100 Mbps ISP** | 100 Mbps | ~12,500,000 bytes/sec |
| **25 Mbps ISP** | 25 Mbps | ~3,125,000 bytes/sec |
| **10 Mbps ISP** | 10 Mbps | ~1,250,000 bytes/sec |
| **1 Mbps ISP** | 1 Mbps | ~125,000 bytes/sec |

### Example Results (2025-12-03)

| Path | Speed | Download Size | Diagnosis |
|------|-------|---------------|-----------|
| Host → Internet | 164 KB/sec | 4.9 MB in 30s | ❌ Slow (ISP issue) |
| VPN → Internet | 817 KB/sec | 10 MB in 12.8s | ✅ 5x faster than ISP |
| Container → Internet | 155 KB/sec | 4.6 MB in 30s | ❌ Same as host (ISP issue) |
| Container → Container | N/A | 0.12s | ✅ Normal |

**Conclusion:** VPN was faster than ISP - slowness was ISP throttling/routing, not VPN.

---

## Common Scenarios

### Scenario 1: VPN Slower Than Direct Connection
```
Host: 10 MB/sec
VPN:  2 MB/sec
```
**Diagnosis:** VPN overhead or poor VPN server performance
**Solutions:**
- Try different VPN server location
- Check VPN provider status
- Verify VPN protocol (OpenVPN vs WireGuard)

### Scenario 2: VPN Faster Than Direct (This Case)
```
Host: 0.16 MB/sec
VPN:  0.82 MB/sec
```
**Diagnosis:** ISP throttling or poor routing
**Solutions:**
- Check if ISP throttles specific traffic
- Test at different times (peak vs off-peak)
- Consider using VPN for more services
- Contact ISP about slow speeds

### Scenario 3: Everything Slow
```
Host: 0.1 MB/sec
VPN:  0.1 MB/sec
Container: 0.1 MB/sec
```
**Diagnosis:** Local network or ISP issue
**Solutions:**
- Test from another device on same network
- Check router logs/status
- Reboot router
- Run ISP speed test (speedtest.net)
- Contact ISP

### Scenario 4: Container-to-Container Slow
```
Container → Container: > 5 seconds
```
**Diagnosis:** Docker networking issue
**Solutions:**
- Check Docker bridge status: `docker network inspect backend_media`
- Restart Docker: `systemctl restart docker` (or TrueNAS Apps)
- Check host resources (CPU/RAM)

---

## Additional Tests

### Full Speed Test (Python)
```bash
ssh lavadmin@truenas.a0a0.org
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```

### Ping Test (Latency)
```bash
# Test to common servers
ping -c 10 8.8.8.8          # Google DNS
ping -c 10 1.1.1.1          # Cloudflare DNS
ping -c 10 proof.ovh.net    # Test server

# From container
sudo docker exec sonarr ping -c 10 8.8.8.8
```

### DNS Resolution Speed
```bash
# Host
time nslookup google.com

# Container
sudo docker exec sonarr time nslookup google.com
```

### VPN Latency Check
```bash
# Check Gluetun logs for connection info
sudo docker logs gluetun | grep -i "ping\|latency\|connected"

# Ping through VPN
sudo docker exec qbittorrent ping -c 10 8.8.8.8
```

### Different Test Servers
```bash
# Cloudflare speed test (100MB)
curl -o /dev/null -w 'Speed: %{speed_download} bytes/sec\n' https://speed.cloudflare.com/__down?bytes=100000000

# Fast.com test (Netflix CDN)
# Visit: https://fast.com in browser

# Speedtest.net CLI
speedtest-cli  # If installed
```

---

## Troubleshooting Slow Speeds

### Step 1: Identify the Bottleneck
Run all 5 quick diagnosis commands above, compare results:

**If VPN is slower:**
- Check VPN logs: `docker logs gluetun | grep -i error`
- Try different VPN server in Gluetun environment variables
- Check VPN provider status page

**If everything is slow:**
- Test from laptop/phone on same network
- Check router status
- Run ISP speed test
- Check for network congestion (time of day)

**If only containers are slow:**
- Check Docker resource limits
- Restart Docker service
- Check host system resources

### Step 2: Check for ISP Throttling
```bash
# Compare different protocols/destinations
curl -o /dev/null -w '%{speed_download}\n' https://proof.ovh.net/files/10Mb.dat
curl -o /dev/null -w '%{speed_download}\n' http://speedtest.tele2.net/10MB.zip
curl -o /dev/null -w '%{speed_download}\n' https://speed.cloudflare.com/__down?bytes=10000000
```

If speeds vary significantly, ISP may be throttling specific traffic.

### Step 3: Check Router/Network
```bash
# Check TrueNAS network interface stats
ip -s link show
ifconfig

# Check for errors/drops
netstat -i

# Check routing table
ip route

# Check DNS resolution
nslookup google.com
```

### Step 4: Time-Based Testing
Test at different times to identify congestion:
```bash
# Create test script
cat > /tmp/speed_test.sh << 'EOF'
#!/bin/bash
echo "$(date): Testing speed..."
curl -o /dev/null -s -w "Speed: %{speed_download} bytes/sec\n" https://proof.ovh.net/files/10Mb.dat
EOF

chmod +x /tmp/speed_test.sh

# Run periodically
watch -n 3600 /tmp/speed_test.sh  # Every hour
```

---

## Performance Baselines

### Expected Docker Overhead
- Container → Internet: 5-10% slower than host (normal)
- VPN: 20-50% slower than direct (encryption overhead)
- Container → Container: < 1ms latency on same host

### When to Worry
- Host → Internet slower than your ISP plan
- VPN more than 50% slower than host (without throttling)
- Container → Container taking > 1 second
- Consistent packet loss (> 5%)

---

## Related Documentation

- [arr-stack/NETWORK-CAPTURE.md](../arr-stack/NETWORK-CAPTURE.md) - Packet capture for troubleshooting
- [Gluetun Wiki](https://github.com/qdm12/gluetun/wiki) - VPN configuration
- [Docker Networking Docs](https://docs.docker.com/network/) - Docker network troubleshooting

---

## Test Server Alternatives

If proof.ovh.net is slow or unreliable:

```bash
# Fast.com (Netflix CDN)
curl -o /dev/null https://fast.com

# Cloudflare
curl -o /dev/null https://speed.cloudflare.com/__down?bytes=10000000

# Tele2 (Europe)
curl -o /dev/null http://speedtest.tele2.net/10MB.zip

# Bouygues (France)
curl -o /dev/null http://speedtest.bouygues.testdebit.info/10M.iso

# Your ISP's speed test server (check ISP website)
```

---

**Remember:** VPN being faster than your ISP is unusual but indicates ISP throttling or routing issues, not a VPN problem.
