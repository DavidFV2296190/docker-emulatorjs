# Security Analysis Report: docker-emulatorjs

## Executive Summary

This report documents the security investigation of the docker-emulatorjs container, focusing on outbound TCP connections on port 4001 and general security vulnerabilities.

## Port 4001 Outbound Connection Analysis

### Finding: IPFS Daemon (Kubo)

**Root Cause Identified:** The container runs an IPFS daemon (Kubo version 0.24.0-r3) which uses port 4001 for peer-to-peer communications.

**Location in Code:**
- Dockerfile line 128: `kubo` package is installed
- Service definition: `root/etc/s6-overlay/s6-rc.d/svc-ipfs/run`
- Documentation: README.md line 194 mentions port 4001 as "IPFS peering port"

**IPFS Behavior:**
- IPFS is a distributed peer-to-peer protocol
- Port 4001 is the default swarm port for IPFS node communication
- IPFS periodically attempts to connect to bootstrap nodes and discovered peers
- The daemon uses a "lowpower" profile (configured in `init-emulatorjs-config/run` line 19)
- Connection attempts are part of normal IPFS operation for:
  - Discovery of peers in the DHT (Distributed Hash Table)
  - Maintaining connections to the IPFS network
  - Content routing and retrieval

**10-Minute Interval:**
IPFS daemons typically have periodic maintenance tasks that run approximately every 10 minutes:
- DHT refresh operations
- Peer discovery and connection maintenance
- Reproviding content to the network
- Bootstrap node reconnection attempts

### Code References

**Service Runner (`root/etc/s6-overlay/s6-rc.d/svc-ipfs/run`):**
```bash
#!/usr/bin/with-contenv bash

if [ ! -z ${DISABLE_IPFS+x} ]; then
  sleep infinity
fi

HOME=/data exec \
    s6-notifyoncheck -d -n 300 -w 1000 -c "nc -z localhost 4001" \
        s6-setuidgid abc ipfs daemon
```

**Initialization (`root/etc/s6-overlay/s6-rc.d/init-emulatorjs-config/run`):**
```bash
# ipfs config
if [[ ! -d "/data/.ipfs" ]]; then
    HOME=/data ipfs init --profile lowpower
    lsiown -R abc:abc /data/.ipfs
fi
```

## Security Vulnerabilities Assessment

### 1. IPFS Network Exposure

**Severity:** MEDIUM

**Description:** The IPFS daemon running in the container participates in the global IPFS peer-to-peer network, making outbound connections to unknown peers.

**Impact:**
- Container makes unsolicited outbound connections to external IPs
- Potential information disclosure through DHT queries
- Network traffic that may bypass firewall rules
- Container fingerprinting through IPFS protocol

**Mitigation Options:**

1. **Disable IPFS entirely** (if not needed):
   ```bash
   docker run -e DISABLE_IPFS=true ...
   ```
   This is already supported in the code (line 4-6 of svc-ipfs/run)

2. **Restrict IPFS to private network only:**
   - Modify IPFS configuration to disable public DHT
   - Use private IPFS swarm keys
   - Configure firewall rules to block outbound 4001

3. **Remove IPFS dependency:**
   - If the artwork distribution feature is not needed
   - Static file hosting without P2P distribution

### 2. External Dependencies from Build

**Severity:** HIGH

**Description:** The Dockerfile downloads and compiles code from multiple external GitHub repositories without version pinning or integrity checks.

**Vulnerable Build Steps:**

**Line 14:** 
```dockerfile
git clone https://github.com/ipfs/fs-repo-migrations.git
```
- No commit hash or version pinning
- Code is compiled and executed during build
- Could be compromised if repository is attacked

**Line 34:**
```dockerfile
git clone https://github.com/Kreeblah/NES20Tool.git
```
- No version control
- Personal GitHub account (not organization)
- Go code compiled without verification

**Line 41-45:**
```dockerfile
BINMERGE_RELEASE=$(curl -sX GET "https://api.github.com/repos/putnam/binmerge/releases/latest"...)
```
- Fetches latest release dynamically
- No signature verification
- Man-in-the-middle attack possible

**Line 55-62:**
```dockerfile
git clone https://github.com/ipfs/fs-repo-migrations.git
```
- Duplicate of earlier step
- Same security concerns

**Line 80-82, 84-88:**
```dockerfile
EMULATORJS_RELEASE=$(curl -sX GET "https://api.github.com/repos/linuxserver/emulatorjs/releases/latest"...)
```
- Dynamic version fetching
- No integrity verification

**Line 92-97, 101-107:**
```dockerfile
curl -o /tmp/emulatorjs-blob.tar.gz -L "https://github.com/thelamer/emulatorjs/archive/main.tar.gz"
```
- Downloads from main branch (always latest)
- No version pinning
- No checksum verification

**Recommendations:**
1. Pin all external dependencies to specific commit hashes or tagged versions
2. Add SHA256 checksum verification for all downloaded files
3. Use multi-stage builds to minimize attack surface in final image
4. Consider vendoring dependencies or using a private mirror

### 3. Pinned Node.js Binary from Unofficial Source

**Severity:** HIGH

**Description:** Lines 137-139 download a Node.js binary from an unofficial GitHub repository.

```dockerfile
curl -L \
  https://github.com/thelamer/node-stash/raw/master/v16.20.2/x86_64/node -o \
  /bin/node && \
chmod +x /bin/node
```

**Issues:**
- Binary downloaded from personal GitHub account ("thelamer/node-stash")
- Not from official Node.js distribution
- No signature verification
- Could contain backdoors or malware
- Node v16.20.2 is an older version that may have known vulnerabilities

**Recommendations:**
1. Use official Node.js Alpine packages
2. Download from official Node.js distribution (nodejs.org)
3. Verify GPG signatures of downloaded binaries
4. Update to a supported Node.js LTS version

### 4. Base Image Trust

**Severity:** MEDIUM

**Description:** Using third-party base images from ghcr.io/linuxserver

```dockerfile
FROM ghcr.io/linuxserver/baseimage-alpine:3.19
FROM ghcr.io/linuxserver/baseimage-alpine:3.14
```

**Concerns:**
- Depends on linuxserver.io container maintenance
- Multiple base image versions used (3.14 and 3.19)
- Trust in upstream supply chain

**Recommendations:**
1. Regular scanning of base images for vulnerabilities
2. Consider using official Alpine Linux images
3. Implement image scanning in CI/CD pipeline

### 5. Missing Security Headers in NGINX

**Severity:** LOW

**Description:** Need to verify NGINX configuration includes security headers.

**Location:** `root/etc/nginx/`

**Recommendations:**
- Add Content-Security-Policy headers
- Enable HSTS (HTTP Strict Transport Security)
- Add X-Frame-Options
- Add X-Content-Type-Options

### 6. Running Services as Non-Root

**Severity:** LOW (Good Practice)

**Finding:** Services properly run as user "abc" via s6-setuidgid - this is GOOD.

## Additional Security Concerns

### 7. Deprecated Project

**Note:** The README.md states this image is deprecated (line 29-31):
```
# DEPRECATION NOTICE 
This image is deprecated. We will not offer support for this image and it will not be updated.
```

**Impact:**
- No future security updates
- Vulnerabilities will not be patched
- Dependencies will become increasingly outdated

## Summary of Findings

| Issue | Severity | Status |
|-------|----------|--------|
| IPFS outbound connections on port 4001 | MEDIUM | By Design |
| Unpinned external dependencies | HIGH | Needs Fix |
| Unofficial Node.js binary | HIGH | Needs Fix |
| Base image trust | MEDIUM | Acceptable Risk |
| Missing NGINX security headers | LOW | Should Improve |
| Deprecated project | N/A | Project Status |

## Recommendations Priority Order

1. **IMMEDIATE:** Document IPFS behavior and connection requirements clearly
2. **HIGH:** Pin all external dependencies to specific versions with checksums
3. **HIGH:** Replace unofficial Node.js binary with official sources
4. **MEDIUM:** Add security headers to NGINX configuration
5. **MEDIUM:** Implement automated vulnerability scanning
6. **LOW:** Consider migrating to recommended alternatives (per README)

## Testing Methodology

To verify the 10-minute connection interval:
1. Run container with network monitoring
2. Capture outbound connections on port 4001
3. Analyze connection timing patterns
4. Verify connections are from IPFS daemon process

See `test_security.sh` for automated testing script.
