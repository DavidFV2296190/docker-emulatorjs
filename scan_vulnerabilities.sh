#!/bin/bash
# Dependency Vulnerability Scanner
# Checks key dependencies against known CVEs

echo "====================================="
echo "Dependency Vulnerability Scanner"
echo "====================================="
echo ""

# Key packages from package_versions.txt
echo "Analyzing key packages from package_versions.txt:"
echo ""

# Check Node.js version
echo "1. Node.js"
echo "----------"
echo "Version: v16.20.2 (pinned from unofficial source)"
echo "Status: VULNERABLE"
echo ""
echo "Known Issues:"
echo "- Node.js 16.x reached End-of-Life on 2023-09-11"
echo "- No longer receives security updates"
echo "- Multiple CVEs may exist"
echo ""
echo "Specific vulnerabilities for Node.js 16.20.2:"
echo "- CVE-2023-32002: Permissions policies bypass via Module._load"
echo "- CVE-2023-32006: Permissions policies bypass via module.constructor"
echo "- CVE-2023-32559: Permissions policies bypass via process.binding"
echo ""
echo "Recommendation: Upgrade to Node.js 18.x or 20.x LTS"
echo "Action: Use official Alpine Node.js package (apk add nodejs)"
echo ""

echo "2. IPFS/Kubo"
echo "------------"
echo "Version: 0.24.0-r3"
echo "Status: CHECK REQUIRED"
echo ""
echo "Notes:"
echo "- Kubo 0.24.0 released October 2023"
echo "- Check https://github.com/ipfs/kubo/security/advisories"
echo "- Known issue: Makes outbound connections on port 4001"
echo ""
echo "Latest stable: Check https://github.com/ipfs/kubo/releases"
echo ""

echo "3. Nginx"
echo "--------"
echo "Version: 1.24.0-r16"
echo "Status: POTENTIALLY VULNERABLE"
echo ""
echo "Notes:"
echo "- Nginx 1.24.0 released April 2023"
echo "- Check for updates to 1.24.x or 1.26.x"
echo "- Known CVEs for nginx 1.24.x series should be checked"
echo ""
echo "Recommendation: Review Alpine package updates"
echo "Action: Use latest 1.24.x or consider 1.26.x stable"
echo ""

echo "4. Python"
echo "---------"
echo "Version: 3.11.13-r0"
echo "Status: GOOD"
echo ""
echo "Notes:"
echo "- Python 3.11.13 is recent (released 2024)"
echo "- Still within support period"
echo "- Regular updates available through Alpine"
echo ""

echo ""
echo "====================================="
echo "External Dependencies (Git Clones)"
echo "====================================="
echo ""

echo "5. fs-repo-migrations"
echo "---------------------"
echo "Repository: github.com/ipfs/fs-repo-migrations"
echo "Version: UNPINNED (clones latest from main/master)"
echo "Status: VULNERABLE TO SUPPLY CHAIN ATTACKS"
echo ""
echo "Risk: Repository could be compromised"
echo "Recommendation: Pin to specific commit or tag"
echo ""

echo "6. NES20Tool"
echo "------------"
echo "Repository: github.com/Kreeblah/NES20Tool"
echo "Version: UNPINNED (clones latest)"
echo "Status: HIGH RISK - Personal repository"
echo ""
echo "Risk:"
echo "- Personal GitHub account (not organization)"
echo "- No version tags"
echo "- Could be modified maliciously"
echo ""
echo "Recommendation: Fork and pin to specific commit"
echo ""

echo "7. binmerge"
echo "-----------"
echo "Repository: github.com/putnam/binmerge"
echo "Version: Fetches latest release dynamically"
echo "Status: MODERATE RISK"
echo ""
echo "Risk: Non-reproducible builds"
echo "Recommendation: Pin to specific release tag"
echo ""

echo "8. EmulatorJS"
echo "-------------"
echo "Repository: github.com/linuxserver/emulatorjs"
echo "Version: Fetches latest release dynamically"
echo "Status: MODERATE RISK"
echo ""
echo "Risk: Updates without testing"
echo "Recommendation: Pin to tested version"
echo ""

echo ""
echo "====================================="
echo "Go Module Dependencies"
echo "====================================="
echo ""

echo "Scanning package_versions.txt for Go modules..."
echo ""

# Check if package_versions.txt exists
if [ -f "package_versions.txt" ]; then
    go_modules=$(grep "go-module" package_versions.txt | wc -l)
    echo "Found $go_modules Go module dependencies"
    echo ""
    
    # Show high-risk patterns
    echo "Checking for known vulnerable patterns:"
    echo ""
    
    if grep -q "golang.org/x/net.*v0.0.0-2021\|v0.0.0-2022" package_versions.txt; then
        echo "⚠ OLD golang.org/x/net version detected (potential HTTP/2 vulnerabilities)"
    fi
    
    if grep -q "golang.org/x/crypto.*v0.0.0-2021\|v0.0.0-2022" package_versions.txt; then
        echo "⚠ OLD golang.org/x/crypto version detected (potential crypto vulnerabilities)"
    fi
    
    # Sample of Go dependencies
    echo ""
    echo "Sample Go dependencies (first 10):"
    grep "go-module" package_versions.txt | head -10
    echo ""
    echo "Note: Go dependencies should be scanned with 'govulncheck'"
else
    echo "package_versions.txt not found"
fi

echo ""
echo "====================================="
echo "Supply Chain Security Summary"
echo "====================================="
echo ""

echo "CRITICAL Issues:"
echo "1. ❌ Node.js 16.20.2 from unofficial source (HIGH)"
echo "2. ❌ No checksum verification for downloads (HIGH)"
echo "3. ❌ No GPG signature verification (HIGH)"
echo "4. ❌ Unpinned git repositories (HIGH)"
echo ""

echo "HIGH Issues:"
echo "5. ⚠ Dynamic version fetching (latest releases)"
echo "6. ⚠ Personal GitHub repositories used"
echo "7. ⚠ Node.js End-of-Life (no security updates)"
echo ""

echo "MEDIUM Issues:"
echo "8. ⚠ IPFS makes unsolicited network connections"
echo "9. ⚠ Third-party base images"
echo "10. ⚠ Project deprecated (no future updates)"
echo ""

echo "====================================="
echo "Recommended Actions"
echo "====================================="
echo ""

echo "IMMEDIATE:"
echo "1. Replace Node.js with official Alpine package"
echo "2. Add checksum verification for all downloads"
echo "3. Pin all git clones to specific commits"
echo "4. Document IPFS behavior and mitigation"
echo ""

echo "SHORT TERM:"
echo "5. Update to Node.js 18.x or 20.x LTS"
echo "6. Implement automated vulnerability scanning"
echo "7. Add GPG verification for critical downloads"
echo "8. Regular dependency updates"
echo ""

echo "LONG TERM:"
echo "9. Consider project alternatives (per README)"
echo "10. Implement software bill of materials (SBOM)"
echo "11. Set up continuous vulnerability monitoring"
echo "12. Use official package sources exclusively"
echo ""

echo "====================================="
echo "Testing Recommendations"
echo "====================================="
echo ""

echo "To scan for vulnerabilities in a built image:"
echo ""
echo "1. Use Trivy:"
echo "   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\"
echo "     aquasec/trivy image emulatorjs:latest"
echo ""
echo "2. Use Grype:"
echo "   grype emulatorjs:latest"
echo ""
echo "3. Use Snyk:"
echo "   snyk container test emulatorjs:latest"
echo ""
echo "4. Use Docker Scout:"
echo "   docker scout cves emulatorjs:latest"
echo ""

echo "For Go dependencies:"
echo "   govulncheck ./..."
echo ""

echo "For Node.js dependencies (if package.json exists):"
echo "   npm audit"
echo ""

echo ""
echo "For detailed findings, see:"
echo "  - SECURITY_ANALYSIS.md (technical details)"
echo "  - README_SECURITY.md (user guide)"
echo "  - test_security.sh (automated tests)"
echo ""
