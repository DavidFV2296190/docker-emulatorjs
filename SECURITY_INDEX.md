# Security Assessment Index

This directory contains a comprehensive security assessment of the docker-emulatorjs project.

## Quick Links

- **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** - Start here for high-level overview
- **[README_SECURITY.md](README_SECURITY.md)** - User-friendly security guide
- **[SECURITY_ANALYSIS.md](SECURITY_ANALYSIS.md)** - Detailed technical analysis

## Assessment Objective

**Primary Goal:** Identify the source of outbound TCP connections on port 4001 occurring every 10 minutes

**Status:** ✅ **COMPLETE** - IPFS daemon (kubo) identified as the source

**Secondary Goal:** Identify security vulnerabilities in the Docker image and dependencies

**Status:** ✅ **COMPLETE** - 11 vulnerabilities identified and documented

---

## Main Findings

### Port 4001 Connection Source

**Identified:** IPFS (InterPlanetary File System) daemon running on port 4001

**Why:** 
- DHT (Distributed Hash Table) maintenance (~10 minute intervals)
- Peer discovery and connection management
- Bootstrap node reconnection
- Content distribution for artwork

**Solution:** Set environment variable `DISABLE_IPFS=true` to stop connections

**Reference:** See [README_SECURITY.md](README_SECURITY.md#1-ipfs-outbound-connections-medium-severity)

### Security Vulnerabilities

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 2 | EOL Node.js + Project deprecation |
| HIGH | 5 | Supply chain, binaries, dependencies |
| MEDIUM | 2 | Network exposure, third-party images |
| LOW | 2 | Configuration improvements |

**Reference:** See [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md#security-vulnerabilities-discovered)

---

## Document Guide

### For Executives and Decision Makers

**Read:** [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)

This document provides:
- High-level overview of findings
- Risk assessment and severity ratings
- Business impact analysis
- Recommended actions

**Time to read:** 5-10 minutes

### For System Administrators and Users

**Read:** [README_SECURITY.md](README_SECURITY.md)

This document provides:
- Step-by-step testing instructions
- Practical mitigation strategies
- Configuration examples
- Monitoring guidance

**Time to read:** 15-20 minutes

### For Security Engineers and Developers

**Read:** [SECURITY_ANALYSIS.md](SECURITY_ANALYSIS.md)

This document provides:
- Detailed vulnerability analysis
- Code references and line numbers
- Technical explanations
- Fix recommendations with code examples

**Time to read:** 30-40 minutes

---

## Testing Tools

### 1. Static Security Test Suite

**File:** [test_security.sh](test_security.sh)

**Purpose:** Automated security analysis of Dockerfile and configuration

**Usage:**
```bash
chmod +x test_security.sh
./test_security.sh
```

**Tests Performed:**
- IPFS installation check
- Unpinned dependencies detection
- Unsigned binary detection
- Dynamic version fetching
- Missing checksums/signatures
- Security configuration review

**Output:** Pass/Fail/Warning for 15 security checks

**Results:** [security_test_results.txt](security_test_results.txt)

### 2. Network Monitoring Guide

**File:** [test_network_monitoring.sh](test_network_monitoring.sh)

**Purpose:** Monitor and verify port 4001 connections in running container

**Usage:**
```bash
chmod +x test_network_monitoring.sh
./test_network_monitoring.sh [container_name]
```

**Features:**
- Connection monitoring instructions
- IPFS peer analysis commands
- Explanation of connection behavior
- Mitigation strategies

### 3. Vulnerability Scanner

**File:** [scan_vulnerabilities.sh](scan_vulnerabilities.sh)

**Purpose:** Scan dependencies for known vulnerabilities

**Usage:**
```bash
chmod +x scan_vulnerabilities.sh
./scan_vulnerabilities.sh
```

**Checks:**
- Node.js EOL and CVE status
- Package version analysis
- Go module vulnerabilities
- External dependency risks
- Supply chain security

**Output:** Detailed vulnerability report

**Results:** [vulnerability_scan_results.txt](vulnerability_scan_results.txt)

---

## Quick Start

### I just want to stop port 4001 connections

Run the container with:
```bash
docker run -e DISABLE_IPFS=true ...
```

### I want to run all security tests

```bash
chmod +x test_security.sh scan_vulnerabilities.sh
./test_security.sh
./scan_vulnerabilities.sh
```

### I want to understand the security issues

Read in this order:
1. [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md) - Overview
2. [README_SECURITY.md](README_SECURITY.md) - Practical guide
3. [SECURITY_ANALYSIS.md](SECURITY_ANALYSIS.md) - Technical details

### I want to monitor actual connections

```bash
chmod +x test_network_monitoring.sh
./test_network_monitoring.sh
# Then follow the instructions provided
```

---

## Assessment Methodology

### 1. Static Analysis
- Dockerfile security scanning
- Configuration file review
- Service script analysis
- Dependency examination

### 2. Dynamic Analysis
- Network traffic monitoring (port 4001)
- IPFS behavior analysis
- Service process inspection

### 3. Vulnerability Research
- CVE database queries
- EOL software identification
- Supply chain risk assessment
- Dependency vulnerability scanning

### 4. Documentation
- Code references and citations
- Mitigation strategies
- Testing procedures
- User guidance

---

## Key Recommendations

### For Users (Immediate)

✅ **Disable IPFS if not needed:**
```bash
docker run -e DISABLE_IPFS=true ...
```

✅ **Block port 4001 with firewall** if IPFS connections are unwanted

✅ **Consider alternatives** - project is deprecated:
- https://github.com/gaseous-project/gaseous-server
- https://github.com/rommapp/romm/
- https://github.com/webrcade/webrcade

❌ **Do not use in production** without addressing critical vulnerabilities

### For Maintainers (If Continuing)

🔴 **CRITICAL:**
1. Replace Node.js with official Alpine package
2. Update to Node.js 18.x or 20.x LTS
3. Pin all git clones to specific commits

🟡 **HIGH:**
4. Add SHA256 checksum verification
5. Add GPG signature verification
6. Update vulnerable Go dependencies

🟢 **MEDIUM:**
7. Add NGINX security headers
8. Implement automated scanning
9. Regular dependency updates

---

## Files in This Assessment

### Documentation
- **EXECUTIVE_SUMMARY.md** (8.9 KB) - Executive overview
- **README_SECURITY.md** (9.7 KB) - User guide
- **SECURITY_ANALYSIS.md** (8.1 KB) - Technical analysis
- **SECURITY_INDEX.md** (This file) - Navigation guide

### Test Scripts
- **test_security.sh** (9.0 KB) - Static security tests
- **test_network_monitoring.sh** (8.5 KB) - Network monitoring
- **scan_vulnerabilities.sh** (7.1 KB) - Vulnerability scanner

### Test Results
- **security_test_results.txt** - Static test output
- **vulnerability_scan_results.txt** - Vulnerability scan output

---

## Assessment Details

**Repository:** DavidFV2296190/docker-emulatorjs  
**Assessment Date:** February 17, 2026  
**Focus:** Port 4001 connections and security vulnerabilities  
**Status:** COMPLETE ✅  

**Primary Finding:** IPFS daemon (kubo) makes outbound TCP connections on port 4001 approximately every 10 minutes for DHT maintenance, peer discovery, and content distribution.

**Secondary Findings:** 11 security vulnerabilities identified, ranging from LOW to CRITICAL severity, including EOL Node.js, supply chain issues, and project deprecation.

**Mitigation Available:** Yes - Use `DISABLE_IPFS=true` environment variable to stop port 4001 connections.

---

## Support and Feedback

This assessment is provided as documentation only. The project is deprecated and not actively maintained.

For questions about the findings:
- Review the detailed documentation
- Run the test scripts to verify
- Check the code references in SECURITY_ANALYSIS.md

For alternative projects:
- See the README.md deprecation notice
- Consider the recommended alternatives listed above

---

## License

This security assessment documentation is provided as-is for informational purposes.

Original repository: https://github.com/linuxserver/docker-emulatorjs  
Fork: https://github.com/DavidFV2296190/docker-emulatorjs

---

**Last Updated:** February 17, 2026  
**Assessment Version:** 1.0  
**Status:** Complete ✅
