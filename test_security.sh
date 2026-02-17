#!/bin/bash
# Security Test Script for docker-emulatorjs
# Tests for port 4001 outbound connections and other security vulnerabilities

# Don't exit on error - we want to run all tests
set +e

echo "====================================="
echo "Security Test Suite: docker-emulatorjs"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

# Function to print test results
print_result() {
    local status=$1
    local message=$2
    
    case $status in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            ((TESTS_PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ((TESTS_FAILED++))
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ((TESTS_WARNING++))
            ;;
        "INFO")
            echo -e "[INFO] $message"
            ;;
    esac
}

# Test 1: Check for IPFS service in Dockerfile
echo "Test 1: Verifying IPFS (kubo) installation"
echo "-------------------------------------------"
if grep -q "kubo" Dockerfile; then
    print_result "FAIL" "IPFS (kubo) package found in Dockerfile (line 128)"
    print_result "INFO" "This is the source of port 4001 outbound connections"
else
    print_result "PASS" "No IPFS package found"
fi
echo ""

# Test 2: Check for IPFS service configuration
echo "Test 2: Checking IPFS service configuration"
echo "--------------------------------------------"
if [ -f "root/etc/s6-overlay/s6-rc.d/svc-ipfs/run" ]; then
    print_result "FAIL" "IPFS service is configured to run automatically"
    
    if grep -q "DISABLE_IPFS" root/etc/s6-overlay/s6-rc.d/svc-ipfs/run; then
        print_result "INFO" "DISABLE_IPFS environment variable is supported"
    else
        print_result "WARN" "No way to disable IPFS found"
    fi
else
    print_result "PASS" "No IPFS service configuration found"
fi
echo ""

# Test 3: Check for port 4001 exposure
echo "Test 3: Checking for port 4001 exposure in documentation"
echo "---------------------------------------------------------"
if grep -q "4001" README.md; then
    print_result "FAIL" "Port 4001 is documented for external exposure"
    grep "4001" README.md | head -3 | sed 's/^/    /'
else
    print_result "PASS" "Port 4001 not documented for exposure"
fi
echo ""

# Test 4: Check for unpinned git clones
echo "Test 4: Checking for unpinned external dependencies"
echo "----------------------------------------------------"
unpinned_count=$(grep -c "git clone" Dockerfile || true)
if [ "$unpinned_count" -gt 0 ]; then
    print_result "FAIL" "Found $unpinned_count unpinned git clone operations"
    grep -n "git clone" Dockerfile | sed 's/^/    Line /'
else
    print_result "PASS" "No unpinned git clones found"
fi
echo ""

# Test 5: Check for unsigned binary downloads
echo "Test 5: Checking for unsigned binary downloads"
echo "-----------------------------------------------"
if grep -q "node-stash" Dockerfile; then
    print_result "FAIL" "Unsigned Node.js binary downloaded from unofficial source"
    grep -n "node-stash" Dockerfile | sed 's/^/    Line /'
else
    print_result "PASS" "No unsigned binaries detected"
fi
echo ""

# Test 6: Check for dynamic version fetching
echo "Test 6: Checking for dynamic version fetching"
echo "----------------------------------------------"
dynamic_count=$(grep -c "releases/latest" Dockerfile || true)
if [ "$dynamic_count" -gt 0 ]; then
    print_result "FAIL" "Found $dynamic_count instances of dynamic version fetching"
    grep -n "releases/latest" Dockerfile | sed 's/^/    Line /'
else
    print_result "PASS" "No dynamic version fetching found"
fi
echo ""

# Test 7: Check for checksum verification
echo "Test 7: Checking for checksum verification"
echo "-------------------------------------------"
if grep -q "sha256sum\|shasum\|md5sum" Dockerfile; then
    print_result "PASS" "Checksum verification found"
else
    print_result "FAIL" "No checksum verification for downloaded files"
fi
echo ""

# Test 8: Check for GPG signature verification
echo "Test 8: Checking for GPG signature verification"
echo "------------------------------------------------"
if grep -q "gpg\|--verify" Dockerfile; then
    print_result "PASS" "GPG verification found"
else
    print_result "FAIL" "No GPG signature verification for external downloads"
fi
echo ""

# Test 9: Analyze IPFS initialization
echo "Test 9: Analyzing IPFS initialization configuration"
echo "----------------------------------------------------"
if [ -f "root/etc/s6-overlay/s6-rc.d/init-emulatorjs-config/run" ]; then
    if grep -q "ipfs init --profile lowpower" root/etc/s6-overlay/s6-rc.d/init-emulatorjs-config/run; then
        print_result "INFO" "IPFS configured with 'lowpower' profile (reduces network usage)"
    fi
    
    if grep -q "fs-repo-migrations" root/etc/s6-overlay/s6-rc.d/init-emulatorjs-config/run; then
        print_result "WARN" "IPFS repository migrations are performed (could be slow)"
    fi
fi
echo ""

# Test 10: Check for deprecated status
echo "Test 10: Checking project status"
echo "---------------------------------"
if grep -q "DEPRECATION NOTICE" README.md; then
    print_result "FAIL" "Project is deprecated and will not receive security updates"
else
    print_result "PASS" "Project appears to be actively maintained"
fi
echo ""

# Test 11: Check base images
echo "Test 11: Checking base image sources"
echo "-------------------------------------"
base_images=$(grep "^FROM" Dockerfile | awk '{print $2}' | sort -u)
for image in $base_images; do
    if [[ $image == *"linuxserver"* ]]; then
        print_result "WARN" "Using third-party base image: $image"
    elif [[ $image == *"alpine"* ]]; then
        print_result "PASS" "Using Alpine Linux base image: $image"
    else
        print_result "INFO" "Base image: $image"
    fi
done
echo ""

# Test 12: Check for exposed ports in Dockerfile
echo "Test 12: Checking exposed ports"
echo "--------------------------------"
if grep -q "EXPOSE" Dockerfile; then
    exposed_ports=$(grep "EXPOSE" Dockerfile | awk '{print $2}')
    print_result "INFO" "Exposed ports: $exposed_ports"
    
    for port in $exposed_ports; do
        if [ "$port" = "4001" ]; then
            print_result "FAIL" "Port 4001 is exposed (IPFS P2P port)"
        fi
    done
else
    print_result "INFO" "No EXPOSE directive found (only ports 80, 3000 documented)"
fi
echo ""

# Test 13: Check for security-sensitive configurations
echo "Test 13: Checking NGINX configuration"
echo "--------------------------------------"
if [ -f "root/etc/nginx/nginx.conf" ]; then
    print_result "INFO" "NGINX configuration file found"
    
    # Check for security headers
    if grep -qi "Content-Security-Policy\|X-Frame-Options\|X-Content-Type-Options" root/etc/nginx/nginx.conf; then
        print_result "PASS" "Security headers configured in NGINX"
    else
        print_result "WARN" "Missing security headers in NGINX configuration"
    fi
else
    print_result "WARN" "NGINX configuration not found at expected location"
fi
echo ""

# Test 14: Check for hardcoded credentials or secrets
echo "Test 14: Scanning for hardcoded secrets"
echo "----------------------------------------"
secret_patterns="password|secret|api_key|token|private_key|aws_access"
if grep -riE "$secret_patterns" root/ --exclude="*.md" > /dev/null 2>&1; then
    print_result "WARN" "Potential secrets found in configuration files"
    grep -riE "$secret_patterns" root/ --exclude="*.md" | head -5 | sed 's/^/    /'
else
    print_result "PASS" "No obvious hardcoded secrets detected"
fi
echo ""

# Test 15: Verify service isolation
echo "Test 15: Checking service user isolation"
echo "-----------------------------------------"
if grep -q "s6-setuidgid abc" root/etc/s6-overlay/s6-rc.d/*/run 2>/dev/null; then
    print_result "PASS" "Services run as non-root user 'abc'"
else
    print_result "FAIL" "Services may be running as root"
fi
echo ""

# Summary
echo ""
echo "====================================="
echo "Test Summary"
echo "====================================="
echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
echo -e "${YELLOW}Warnings: $TESTS_WARNING${NC}"
echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
echo ""

# Return appropriate exit code
if [ $TESTS_FAILED -gt 0 ]; then
    echo "RESULT: Security vulnerabilities detected!"
    echo ""
    echo "Key Findings:"
    echo "1. IPFS daemon (kubo) makes outbound connections on port 4001"
    echo "2. External dependencies are not pinned or verified"
    echo "3. Node.js binary downloaded from unofficial source"
    echo "4. Project is deprecated and won't receive security updates"
    echo ""
    echo "See SECURITY_ANALYSIS.md for detailed findings and recommendations."
    exit 1
else
    echo "RESULT: No critical security issues detected (warnings should be reviewed)"
    exit 0
fi
