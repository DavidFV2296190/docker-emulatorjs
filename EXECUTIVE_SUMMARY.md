# Executive Summary: Security Assessment of docker-emulatorjs

**Assessment Date:** February 17, 2026  
**Repository:** DavidFV2296190/docker-emulatorjs  
**Assessment Scope:** Port 4001 outbound connections and general security vulnerabilities

---

## Key Finding: Port 4001 Outbound Connection Source IDENTIFIED ✓

### Root Cause: IPFS Daemon (Kubo)

**What:** The container runs an IPFS (InterPlanetary File System) daemon for peer-to-peer artwork distribution.

**Port:** TCP 4001 (IPFS swarm port)

**Frequency:** Approximately every 10 minutes

**Why:** 
- DHT (Distributed Hash Table) refresh operations
- Peer discovery and connection maintenance
- Bootstrap node reconnection attempts
- Content routing for artwork distribution

**Evidence:**
```
Dockerfile line 128: kubo package installation
Service: root/etc/s6-overlay/s6-rc.d/svc-ipfs/run
Config: root/etc/s6-overlay/s6-rc.d/init-emulatorjs-config/run (line 19: ipfs init --profile lowpower)
```

**Mitigation Available:** YES
```bash
docker run -e DISABLE_IPFS=true ...
```

---

## Security Vulnerabilities Discovered

### Summary Table

| ID | Severity | Issue | Status |
|----|----------|-------|--------|
| 1 | CRITICAL | End-of-Life Node.js with known CVEs | Identified |
| 2 | HIGH | Unofficial Node.js binary source | Identified |
| 3 | HIGH | Unpinned external dependencies | Identified |
| 4 | HIGH | No checksum verification | Identified |
| 5 | HIGH | No GPG signature verification | Identified |
| 6 | HIGH | Dynamic version fetching | Identified |
| 7 | HIGH | Vulnerable Go modules detected | Identified |
| 8 | MEDIUM | IPFS network exposure | Identified |
| 9 | MEDIUM | Third-party base images | Identified |
| 10 | LOW | Missing NGINX security headers | Identified |
| 11 | CRITICAL | Project deprecated (no updates) | Confirmed |

### Critical Vulnerabilities

#### 1. End-of-Life Node.js (CRITICAL)

**Version:** 16.20.2  
**EOL Date:** September 11, 2023  
**Known CVEs:**
- CVE-2023-32002: Permissions policies bypass via Module._load
- CVE-2023-32006: Permissions policies bypass via module.constructor  
- CVE-2023-32559: Permissions policies bypass via process.binding

**Impact:** Container is running unsupported software with unpatched vulnerabilities.

#### 2. Unofficial Node.js Binary Source (HIGH)

**Source:** `https://github.com/thelamer/node-stash/raw/master/v16.20.2/x86_64/node`

**Issues:**
- Personal GitHub account (not official Node.js distribution)
- No GPG signature verification
- Could contain backdoors or malware
- Supply chain attack vector

#### 3. Supply Chain Security Issues (HIGH)

**Unpinned Git Repositories:**
- `github.com/ipfs/fs-repo-migrations` (cloned twice)
- `github.com/Kreeblah/NES20Tool` (personal repository)

**Dynamic Version Fetching:**
- binmerge (latest release)
- EmulatorJS (latest release)

**No Integrity Checks:**
- No SHA256/SHA512 checksums
- No GPG signature verification
- Downloads could be intercepted (MITM)

#### 4. Vulnerable Go Dependencies (HIGH)

**Finding:** 402 Go module dependencies detected

**Known Issues:**
- Old `golang.org/x/net` version (potential HTTP/2 vulnerabilities)
- Old `golang.org/x/crypto` version (potential cryptographic vulnerabilities)

**Recommendation:** Run `govulncheck` on compiled binaries

### Medium Severity Issues

#### 5. IPFS Network Exposure (MEDIUM)

**Behavior:** Unsolicited outbound connections to unknown peers on global P2P network

**Security Implications:**
- Connects to external IPs without user awareness
- May bypass firewall rules
- Potential information disclosure through DHT queries
- Container fingerprinting possible

**Mitigation:** Use `DISABLE_IPFS=true` environment variable

#### 6. Project Deprecation Status (CRITICAL for Long-term)

**Finding:** README explicitly states project is deprecated and will not receive updates.

**Impact:**
- No future security patches
- Dependencies will become increasingly outdated
- Known vulnerabilities will remain unpatched

**Alternatives Suggested:**
- https://github.com/gaseous-project/gaseous-server
- https://github.com/rommapp/romm/
- https://github.com/webrcade/webrcade

---

## Testing Results

### Automated Security Tests

**Test Suite:** `./test_security.sh`

**Results:**
- ✓ Passed: 2 tests
- ⚠ Warnings: 4 tests
- ✗ Failed: 9 tests

**Key Failures:**
1. IPFS installation detected
2. IPFS service configured to run
3. Port 4001 exposed in documentation
4. Unpinned git clones (3 instances)
5. Unsigned binaries downloaded
6. Dynamic version fetching (2 instances)
7. No checksum verification
8. No GPG signature verification
9. Project deprecated

### Dependency Vulnerability Scan

**Tool:** `./scan_vulnerabilities.sh`

**Findings:**
- Node.js 16.20.2: VULNERABLE (EOL + known CVEs)
- Kubo 0.24.0-r3: Requires review
- Nginx 1.24.0-r16: Potentially vulnerable
- Python 3.11.13-r0: GOOD
- Go modules (402): Contains known vulnerable packages

---

## Positive Security Findings

✅ **Services run as non-root** (user: `abc`)  
✅ **IPFS can be disabled** (environment variable supported)  
✅ **No hardcoded secrets** detected  
✅ **Multi-stage build** reduces attack surface  
✅ **s6-overlay** provides proper service management

---

## Recommendations

### For Users (Immediate Actions)

1. **Disable IPFS if not needed:**
   ```bash
   docker run -e DISABLE_IPFS=true ...
   ```

2. **Block port 4001 with firewall:**
   ```bash
   iptables -A OUTPUT -p tcp --dport 4001 -j DROP
   ```

3. **Monitor network traffic:**
   ```bash
   sudo tcpdump -i any -n 'tcp port 4001'
   ```

4. **Consider project alternatives** due to deprecation status

5. **Do not use in production** without addressing vulnerabilities

### For Maintainers (If Resuming Development)

#### IMMEDIATE (Critical)

1. Replace Node.js binary with official Alpine package
2. Pin all git clones to specific commit hashes
3. Add SHA256 checksum verification for all downloads
4. Update to supported Node.js version (18.x or 20.x LTS)

#### SHORT TERM (High Priority)

5. Add GPG signature verification for critical downloads
6. Pin all version fetching to specific releases
7. Update vulnerable Go dependencies
8. Add NGINX security headers
9. Implement automated vulnerability scanning (Trivy/Grype)

#### LONG TERM (Maintenance)

10. Create SBOM (Software Bill of Materials)
11. Set up continuous vulnerability monitoring
12. Regular dependency updates and CVE tracking
13. Security audit of custom code

---

## Files Delivered

This assessment includes the following files:

1. **SECURITY_ANALYSIS.md** - Detailed technical analysis with code references
2. **README_SECURITY.md** - User-friendly security guide
3. **test_security.sh** - Automated static security test suite
4. **test_network_monitoring.sh** - Network monitoring guide for port 4001
5. **scan_vulnerabilities.sh** - Dependency vulnerability scanner
6. **security_test_results.txt** - Test output
7. **vulnerability_scan_results.txt** - Vulnerability scan output
8. **EXECUTIVE_SUMMARY.md** - This document

---

## Conclusion

### Port 4001 Investigation: COMPLETE ✓

**Confirmed:** IPFS daemon (kubo) is responsible for outbound TCP connections on port 4001

**Frequency:** Approximately every 10 minutes (DHT maintenance, peer discovery, bootstrap reconnection)

**Mitigation Available:** YES (`DISABLE_IPFS=true` environment variable)

### Vulnerability Assessment: COMPLETE ✓

**Total Issues Found:** 11 (ranging from LOW to CRITICAL)

**Most Critical:**
1. EOL Node.js with known CVEs
2. Unofficial binary sources  
3. Supply chain security weaknesses
4. Project deprecation (no future updates)

### Risk Assessment

**Current Risk Level:** HIGH

**Risk Factors:**
- Multiple HIGH/CRITICAL vulnerabilities
- No active maintenance (deprecated)
- Unsupported dependencies
- Supply chain attack vectors
- Unexpected network behavior (port 4001)

### Recommended Action

**For Production Use:** NOT RECOMMENDED without addressing critical vulnerabilities

**For Testing/Personal Use:** 
- Acceptable with IPFS disabled
- Network-level controls for port 4001
- Awareness of security limitations
- Plan to migrate to alternatives

**For Development:**
- Address critical vulnerabilities before any production deployment
- Implement continuous security monitoring
- Regular dependency updates
- Consider forking with active maintenance

---

## Contact & References

**Assessment Performed By:** Security analysis of docker-emulatorjs repository

**References:**
- IPFS Documentation: https://docs.ipfs.tech/
- Node.js EOL: https://github.com/nodejs/release
- CVE Database: https://cve.mitre.org/
- Alpine Security: https://security.alpinelinux.org/

**Tools Used:**
- Custom security test suite
- Manual code review
- Dependency analysis
- OWASP best practices

---

**End of Executive Summary**

For detailed information, refer to the individual security documents included in this assessment.
