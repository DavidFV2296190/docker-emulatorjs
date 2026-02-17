# ⚠️ SECURITY ASSESSMENT COMPLETED

## Port 4001 Connection Investigation - RESOLVED ✓

**Finding:** The outbound TCP connections on port 4001 are caused by the **IPFS (InterPlanetary File System) daemon (kubo)** running in the container.

**Frequency:** Approximately every 10 minutes

**Purpose:** 
- DHT (Distributed Hash Table) refresh
- Peer discovery and maintenance
- Bootstrap node connections
- Artwork distribution via P2P network

## Quick Solution

To disable IPFS and stop port 4001 connections:

```bash
docker run -e DISABLE_IPFS=true \
  -p 3000:3000 \
  -p 80:80 \
  -v /path/to/config:/config \
  -v /path/to/data:/data \
  lscr.io/linuxserver/emulatorjs:latest
```

**Note:** This disables the P2P artwork distribution feature but the container will still function for local ROM management and emulation.

## Security Vulnerabilities Identified

This assessment also identified **11 security vulnerabilities** in the Docker image:

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH | 5 |
| MEDIUM | 2 |
| LOW | 2 |

### Most Critical Issues

1. **Node.js 16.20.2** - End-of-Life with 3 known CVEs
2. **Unofficial Node.js binary** from unverified source
3. **Unpinned dependencies** vulnerable to supply chain attacks
4. **No checksum verification** for downloads
5. **Project deprecated** - will not receive security updates

## Documentation

Complete security assessment available in:

- 📋 **[SECURITY_INDEX.md](SECURITY_INDEX.md)** - START HERE - Navigation guide
- 📊 **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** - High-level overview
- 📖 **[README_SECURITY.md](README_SECURITY.md)** - User-friendly guide
- 🔍 **[SECURITY_ANALYSIS.md](SECURITY_ANALYSIS.md)** - Technical details

## Testing Tools Included

Run these scripts to verify the findings:

```bash
# Static security analysis
./test_security.sh

# Dependency vulnerability scan
./scan_vulnerabilities.sh

# Network monitoring guide
./test_network_monitoring.sh
```

## Recommendations

### For Users

✅ **Use `DISABLE_IPFS=true`** if you don't need P2P distribution  
✅ **Block port 4001** with firewall if connections are unwanted  
✅ **Consider alternatives** - this project is deprecated  
❌ **Do not use in production** without addressing vulnerabilities  

### Recommended Alternatives

As noted in the main README, this project is deprecated. Consider:

- https://github.com/gaseous-project/gaseous-server
- https://github.com/rommapp/romm/
- https://github.com/webrcade/webrcade

## Assessment Status

✅ Port 4001 source identified  
✅ Security vulnerabilities documented  
✅ Mitigation strategies provided  
✅ Testing tools created  
✅ Comprehensive documentation completed  

**Assessment Date:** February 17, 2026  
**Status:** COMPLETE

---

For full details, see [SECURITY_INDEX.md](SECURITY_INDEX.md)
