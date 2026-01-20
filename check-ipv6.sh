#!/bin/bash

echo "=== IPv6 Diagnostics ==="
echo ""

echo "1. Network interfaces and IPv6 addresses:"
ip -6 addr show

echo ""
echo "2. IPv6 routing table:"
ip -6 route show

echo ""
echo "3. IPv6 connectivity test (ping Google DNS):"
ping6 -c 3 2001:4860:4860::8888 2>&1 || echo "IPv6 ping failed"

echo ""
echo "4. Check if IPv6 is enabled in kernel:"
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

echo ""
echo "5. Matter device listening ports:"
netstat -ln6 | grep -E '5540|5560'

echo ""
echo "=== End Diagnostics ==="
