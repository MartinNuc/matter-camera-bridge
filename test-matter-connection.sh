#!/bin/bash

echo "=== Matter Device Connection Test ==="
echo ""

# Get the primary IPv6 address
IPV6_ADDR=$(ip -6 addr show enp0s18 | grep "scope global" | head -1 | awk '{print $2}' | cut -d'/' -f1)

echo "1. Primary IPv6 address: $IPV6_ADDR"
echo ""

echo "2. Testing UDP port 5540 (Matter commissioning):"
echo "   Listening on all interfaces:"
netstat -ln6 | grep 5540
echo ""

echo "3. Testing TCP port 5540 (Matter commissioning):"
netstat -ln | grep 5540
echo ""

echo "4. Firewall status (iptables IPv6):"
ip6tables -L -n -v 2>/dev/null || echo "   ip6tables not available or no rules"
echo ""

echo "5. Check if port 5540 is reachable from outside:"
echo "   From your Mac or iPhone, try:"
echo "   nc -6 -u -v $IPV6_ADDR 5540"
echo ""

echo "6. Matter device process:"
ps aux | grep matter-camera-bridge | grep -v grep
echo ""

echo "7. Open ports on this system:"
ss -tuln6 | grep -E '5540|5560'
echo ""

echo "=== Test Complete ==="
echo ""
echo "To test from your Mac:"
echo "  nc -6 -u -v $IPV6_ADDR 5540"
echo ""
echo "If connection fails, check:"
echo "  - Proxmox firewall settings"
echo "  - Home Assistant firewall"
echo "  - Router firewall rules"
