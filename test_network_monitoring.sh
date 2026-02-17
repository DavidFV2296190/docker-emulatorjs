#!/bin/bash
# Network Monitoring Test for IPFS Port 4001 Connections
# This script can be used to monitor actual network connections when the container is running

set -e

echo "====================================="
echo "Network Monitoring Test: Port 4001"
echo "====================================="
echo ""

# Check if we're testing a running container or just analyzing the code
CONTAINER_NAME="${1:-emulatorjs}"

echo "This script demonstrates how to monitor for port 4001 connections."
echo ""
echo "EXPECTED BEHAVIOR:"
echo "  - IPFS daemon (kubo) will attempt outbound connections on port 4001"
echo "  - Connections occur periodically (approximately every 10 minutes)"
echo "  - Connections are to IPFS bootstrap nodes and discovered peers"
echo ""
echo "TECHNICAL DETAILS:"
echo "  - IPFS uses port 4001 for peer-to-peer swarm connections"
echo "  - The 'lowpower' profile reduces frequency of connections"
echo "  - DHT (Distributed Hash Table) refresh happens periodically"
echo "  - Bootstrap node reconnection attempts occur regularly"
echo ""

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    echo ""
    echo "To test this, you would need to:"
    echo "1. Build the docker image"
    echo "2. Run the container with network monitoring"
    echo "3. Observe connections over a 15-20 minute period"
    exit 1
fi

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' found."
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Status: RUNNING"
        echo ""
        
        echo "MONITORING OPTIONS:"
        echo ""
        echo "1. Monitor from host with tcpdump:"
        echo "   sudo tcpdump -i any -n 'tcp port 4001' -c 100"
        echo ""
        echo "2. Check current connections in container:"
        echo "   docker exec ${CONTAINER_NAME} netstat -an | grep 4001"
        echo ""
        echo "3. Monitor IPFS logs:"
        echo "   docker exec ${CONTAINER_NAME} tail -f /config/.ipfs/logs/*.log"
        echo ""
        echo "4. Check IPFS peers:"
        echo "   docker exec ${CONTAINER_NAME} ipfs swarm peers"
        echo ""
        
        # Try to get current connection status
        echo "CURRENT CONNECTION STATUS:"
        echo "--------------------------"
        if docker exec "${CONTAINER_NAME}" sh -c "command -v netstat" &>/dev/null; then
            docker exec "${CONTAINER_NAME}" netstat -an 2>/dev/null | grep -E "4001|LISTEN" | head -20 || echo "No connections on port 4001 currently"
        elif docker exec "${CONTAINER_NAME}" sh -c "command -v ss" &>/dev/null; then
            docker exec "${CONTAINER_NAME}" ss -an 2>/dev/null | grep -E "4001|LISTEN" | head -20 || echo "No connections on port 4001 currently"
        else
            echo "Network monitoring tools not available in container"
        fi
        echo ""
        
        # Try to check IPFS status
        echo "IPFS DAEMON STATUS:"
        echo "-------------------"
        if docker exec "${CONTAINER_NAME}" sh -c "command -v ipfs" &>/dev/null; then
            # Check if IPFS is running
            if docker exec "${CONTAINER_NAME}" pgrep -f "ipfs daemon" &>/dev/null; then
                echo "✓ IPFS daemon is running"
                
                # Try to get swarm info
                peer_count=$(docker exec "${CONTAINER_NAME}" sh -c "HOME=/data ipfs swarm peers 2>/dev/null | wc -l" || echo "0")
                echo "✓ Connected to $peer_count peers"
                
                # Show sample of connected peers
                if [ "$peer_count" -gt "0" ]; then
                    echo ""
                    echo "Sample of connected peers (showing max 5):"
                    docker exec "${CONTAINER_NAME}" sh -c "HOME=/data ipfs swarm peers 2>/dev/null" | head -5 | sed 's/^/  /'
                fi
            else
                echo "✗ IPFS daemon is not running (may be disabled with DISABLE_IPFS)"
            fi
        else
            echo "IPFS command not available"
        fi
        echo ""
        
        echo "TO MONITOR CONNECTIONS OVER TIME:"
        echo "----------------------------------"
        echo "Run this command and let it run for 15-20 minutes:"
        echo ""
        echo "  watch -n 30 'docker exec ${CONTAINER_NAME} sh -c \"HOME=/data ipfs swarm peers 2>/dev/null | wc -l\"'"
        echo ""
        echo "Or monitor with timestamps:"
        echo ""
        echo "  while true; do"
        echo "    echo \"\$(date): \$(docker exec ${CONTAINER_NAME} sh -c 'HOME=/data ipfs swarm peers 2>/dev/null | wc -l') peers\""
        echo "    sleep 60"
        echo "  done"
        echo ""
        
    else
        echo "Status: STOPPED"
        echo ""
        echo "Start the container to monitor network activity:"
        echo "  docker start ${CONTAINER_NAME}"
    fi
else
    echo "Container '${CONTAINER_NAME}' not found."
    echo ""
    echo "To test port 4001 connections, you need to:"
    echo ""
    echo "1. Build the image:"
    echo "   docker build -t emulatorjs-test:latest ."
    echo ""
    echo "2. Run the container with monitoring:"
    echo "   docker run -d --name ${CONTAINER_NAME} \\"
    echo "     -p 3000:3000 \\"
    echo "     -p 80:80 \\"
    echo "     -p 4001:4001 \\"
    echo "     -v emulatorjs-data:/data \\"
    echo "     -v emulatorjs-config:/config \\"
    echo "     emulatorjs-test:latest"
    echo ""
    echo "3. To run WITHOUT IPFS (disable port 4001 connections):"
    echo "   docker run -d --name ${CONTAINER_NAME} \\"
    echo "     -e DISABLE_IPFS=true \\"
    echo "     -p 3000:3000 \\"
    echo "     -p 80:80 \\"
    echo "     -v emulatorjs-data:/data \\"
    echo "     -v emulatorjs-config:/config \\"
    echo "     emulatorjs-test:latest"
    echo ""
    echo "4. Monitor with tcpdump from host:"
    echo "   sudo tcpdump -i any -n 'tcp port 4001' -w ipfs_connections.pcap"
    echo ""
    echo "5. After 15-20 minutes, analyze the capture:"
    echo "   tcpdump -r ipfs_connections.pcap -n 'tcp port 4001' | less"
fi

echo ""
echo "====================================="
echo "EXPLANATION OF PORT 4001 CONNECTIONS"
echo "====================================="
echo ""
echo "WHY DOES IPFS CONNECT ON PORT 4001?"
echo ""
echo "IPFS (InterPlanetary File System) is a peer-to-peer distributed file system."
echo "Port 4001 is the default 'swarm' port used for P2P connections."
echo ""
echo "WHAT CONNECTIONS ARE MADE?"
echo ""
echo "1. Bootstrap Node Connections:"
echo "   - On startup, IPFS connects to bootstrap nodes to join the network"
echo "   - Default bootstrap nodes are operated by Protocol Labs"
echo ""
echo "2. DHT Operations:"
echo "   - Distributed Hash Table queries for content routing"
echo "   - Peer discovery and network topology maintenance"
echo "   - Periodic refresh operations (every ~10 minutes)"
echo ""
echo "3. Content Retrieval:"
echo "   - When fetching artwork/assets, connects to peers hosting the content"
echo "   - EmulatorJS uses IPFS for distributing frontend assets"
echo ""
echo "4. Periodic Maintenance:"
echo "   - Connection keep-alives"
echo "   - DHT routing table refresh"
echo "   - Peer discovery and connection management"
echo "   - These typically run on intervals (approximately 10 minutes)"
echo ""
echo "SECURITY IMPLICATIONS:"
echo ""
echo "• Outbound connections to unknown external IP addresses"
echo "• Traffic may bypass standard firewall rules for HTTP/HTTPS"
echo "• Participation in global P2P network"
echo "• Potential for metadata leakage through DHT queries"
echo ""
echo "MITIGATION OPTIONS:"
echo ""
echo "1. Disable IPFS entirely (if artwork distribution not needed):"
echo "   docker run -e DISABLE_IPFS=true ..."
echo ""
echo "2. Firewall port 4001 (blocks P2P network participation):"
echo "   iptables -A OUTPUT -p tcp --dport 4001 -j DROP"
echo ""
echo "3. Use private IPFS network (not connected to public network):"
echo "   - Requires custom IPFS swarm key configuration"
echo "   - Only connects to peers with the same key"
echo ""
echo "4. Monitor and log all connections on port 4001:"
echo "   - Use network monitoring tools"
echo "   - Analyze connection patterns"
echo "   - Validate destination IP addresses"
echo ""

echo "For detailed security analysis, see: SECURITY_ANALYSIS.md"
echo ""
