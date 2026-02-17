# Security Testing and Vulnerability Assessment

## Overview

This repository has been analyzed for security vulnerabilities, with a focus on identifying the source of outbound TCP connections on port 4001.

## Quick Summary of Findings

### Port 4001 Connections - **IDENTIFIED**

**Root Cause:** IPFS daemon (Kubo) used for peer-to-peer artwork distribution

- **Service:** IPFS daemon (kubo v0.24.0-r3)
- **Port:** 4001 (TCP)
- **Frequency:** Approximately every 10 minutes
- **Purpose:** DHT refresh, peer discovery, bootstrap node connections
- **Configuration:** `lowpower` profile (reduces connection frequency)

### Vulnerability Summary

| Severity | Count | Type |
|----------|-------|------|
| HIGH | 2 | Supply chain security issues |
| MEDIUM | 1 | Network exposure (IPFS) |
| LOW | 2 | Configuration improvements needed |

## Running the Security Tests

### 1. Static Security Analysis

Run the automated security test suite:

```bash
./test_security.sh
```

This will check for:
- IPFS installation and configuration
- Unpinned external dependencies
- Unsigned binary downloads
- Dynamic version fetching
- Missing checksum/signature verification
- Security headers in NGINX
- Project deprecation status
- Service isolation

**Expected Output:** Test results showing PASS/FAIL/WARN for each security check

### 2. Network Monitoring Test

To monitor actual port 4001 connections (requires running container):

```bash
./test_network_monitoring.sh [container_name]
```

This script provides:
- Instructions for monitoring network connections
- Commands to check IPFS peer connections
- Explanation of IPFS behavior
- Mitigation strategies

**Note:** The container build may fail on some platforms due to base image compatibility. The tests analyze the Dockerfile and configuration files directly.

## Detailed Findings

### 1. IPFS Outbound Connections (MEDIUM Severity)

**Issue:** The IPFS daemon makes unsolicited outbound connections on port 4001 to participate in the global IPFS peer-to-peer network.

**Evidence:**
- Dockerfile line 128: `kubo` package installed
- Service file: `root/etc/s6-overlay/s6-rc.d/svc-ipfs/run`
- Documentation: README.md explicitly mentions port 4001

**Behavior:**
- Connects to IPFS bootstrap nodes on startup
- Periodic DHT (Distributed Hash Table) refresh (~10 minutes)
- Peer discovery and connection maintenance
- Content routing queries

**Mitigation:**

Option 1 - Disable IPFS (recommended if not using artwork distribution):
```bash
docker run -e DISABLE_IPFS=true ...
```

Option 2 - Block port 4001 with firewall:
```bash
iptables -A OUTPUT -p tcp --dport 4001 -j DROP
```

Option 3 - Use private IPFS network (advanced):
- Configure custom swarm key
- Only connects to known peers

### 2. Unpinned External Dependencies (HIGH Severity)

**Issue:** Multiple external repositories are cloned and compiled without version pinning.

**Affected Lines:**
- Line 14: `git clone https://github.com/ipfs/fs-repo-migrations.git`
- Line 34: `git clone https://github.com/Kreeblah/NES20Tool.git`
- Line 55: `git clone https://github.com/ipfs/fs-repo-migrations.git` (duplicate)

**Risk:**
- Malicious code could be injected if repositories are compromised
- Build reproducibility issues
- Unexpected breaking changes

**Recommendation:**
```dockerfile
# Instead of:
git clone https://github.com/ipfs/fs-repo-migrations.git

# Use:
git clone --depth 1 --branch v2.0.2 https://github.com/ipfs/fs-repo-migrations.git
# Or pin to specific commit:
git clone https://github.com/ipfs/fs-repo-migrations.git && \
  cd fs-repo-migrations && \
  git checkout abc123def456... # specific commit hash
```

### 3. Unsigned Node.js Binary (HIGH Severity)

**Issue:** Node.js binary downloaded from unofficial personal GitHub repository.

**Affected Line:**
```dockerfile
curl -L \
  https://github.com/thelamer/node-stash/raw/master/v16.20.2/x86_64/node -o \
  /bin/node
```

**Problems:**
- Not from official Node.js distribution
- No GPG signature verification
- Using Node v16.20.2 (may have known vulnerabilities)
- Binary could contain malware

**Recommendation:**
```dockerfile
# Use official Node.js Alpine package instead:
apk add --no-cache nodejs=~16.20

# Or download from official source with verification:
curl -fsSL https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64.tar.xz -o node.tar.xz && \
curl -fsSL https://nodejs.org/dist/v16.20.2/SHASUMS256.txt.asc -o SHASUMS256.txt.asc && \
gpg --verify SHASUMS256.txt.asc && \
sha256sum -c SHASUMS256.txt.asc 2>&1 | grep node-v16.20.2-linux-x64.tar.xz
```

### 4. Dynamic Version Fetching (HIGH Severity)

**Issue:** Latest release versions are fetched dynamically during build.

**Affected Lines:**
- Line 41: `BINMERGE_RELEASE=$(curl ... releases/latest)`
- Line 80: `EMULATORJS_RELEASE=$(curl ... releases/latest)`

**Risk:**
- Non-reproducible builds
- Unexpected breaking changes
- API rate limiting issues
- Build failures if GitHub API is down

**Recommendation:**
```dockerfile
# Pin versions explicitly:
ARG EMULATORJS_RELEASE=v1.2.3
ARG BINMERGE_RELEASE=v2.1.0

# Or use specific commit hash in download URL
```

### 5. No Checksum Verification (HIGH Severity)

**Issue:** Downloaded files are not verified with checksums.

**Risk:**
- Man-in-the-middle attacks
- Corrupted downloads
- Supply chain attacks

**Recommendation:**
```dockerfile
# Add checksum verification:
curl -o file.tar.gz https://example.com/file.tar.gz && \
echo "expected_sha256_hash  file.tar.gz" | sha256sum -c - && \
tar xf file.tar.gz
```

### 6. Missing NGINX Security Headers (LOW Severity)

**Issue:** NGINX configuration may be missing security headers.

**Recommended Headers:**
```nginx
add_header Content-Security-Policy "default-src 'self';" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### 7. Project Deprecated (CRITICAL Status)

**Issue:** Project README states this image is deprecated and will not receive updates.

**Impact:**
- No security patches will be released
- Dependencies will become increasingly outdated
- Known vulnerabilities will remain unpatched

**Recommendation:**
Consider migrating to recommended alternatives:
- https://github.com/gaseous-project/gaseous-server
- https://github.com/rommapp/romm/
- https://github.com/webrcade/webrcade

## Positive Security Findings

✅ **Services run as non-root user** (`abc` user via s6-setuidgid)
✅ **IPFS can be disabled** (DISABLE_IPFS environment variable supported)
✅ **No obvious hardcoded secrets** in configuration files
✅ **Multi-stage build** reduces final image size and attack surface

## Testing Methodology

### Static Analysis
1. Dockerfile security scanning
2. Service configuration review
3. Dependency analysis
4. Configuration file inspection

### Dynamic Analysis (when running)
1. Network traffic monitoring on port 4001
2. IPFS peer connection analysis
3. Service process inspection
4. Log file analysis

### Tools Used
- Custom shell scripts for security testing
- grep/find for code analysis
- Docker for container inspection
- (CodeQL not applicable - no supported languages)

## Recommendations for Production Use

### Immediate Actions

1. **Document IPFS behavior** - Users should understand port 4001 connections
2. **Provide DISABLE_IPFS option** - Already exists, should be prominently documented
3. **Add security warning** - Note that image is deprecated

### If Continuing Development

1. **Pin all dependencies** to specific versions with checksums
2. **Use official Node.js** from Alpine repositories
3. **Add checksum verification** for all downloads
4. **Implement vulnerability scanning** in CI/CD pipeline
5. **Add security headers** to NGINX configuration
6. **Document security posture** in README
7. **Regular dependency updates** and CVE monitoring

### For Users

1. **Use DISABLE_IPFS=true** if P2P distribution not needed
2. **Firewall port 4001** if IPFS connections are unwanted
3. **Monitor network traffic** to understand actual behavior
4. **Consider alternatives** given deprecation status
5. **Run behind reverse proxy** with security headers
6. **Keep base system updated** even if container is deprecated

## Files in This Security Assessment

- **SECURITY_ANALYSIS.md** - Detailed vulnerability analysis with code references
- **test_security.sh** - Automated security test suite (static analysis)
- **test_network_monitoring.sh** - Network monitoring guide and tools
- **security_test_results.txt** - Sample output from security tests
- **README_SECURITY.md** - This file (user-friendly guide)

## Conclusion

The investigation successfully identified that **IPFS (kubo) is the source of outbound TCP connections on port 4001**, with connections occurring approximately every 10 minutes for DHT maintenance and peer discovery.

Additionally, several **HIGH severity supply chain security issues** were discovered related to unpinned dependencies and unsigned binaries.

The good news is that IPFS can be disabled with the `DISABLE_IPFS=true` environment variable if the artwork distribution feature is not needed.

Given the project's deprecated status, users should consider:
1. Disabling IPFS if not needed
2. Implementing network-level controls for port 4001
3. Migrating to actively maintained alternatives
4. Not using this container for sensitive/production environments

---

**Generated by:** Security assessment of docker-emulatorjs repository
**Date:** 2026-02-17
**Focus:** Port 4001 outbound connections and general security vulnerabilities
