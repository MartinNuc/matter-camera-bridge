#!/usr/bin/env bash
set -e

echo "Starting Matter 1.5 Virtual Camera Bridge..."

# Run IPv6 diagnostics
if [ -f /app/check-ipv6.sh ]; then
    echo ""
    echo "Running IPv6 diagnostics..."
    bash /app/check-ipv6.sh
    echo ""
fi

# Run connection test
if [ -f /app/test-matter-connection.sh ]; then
    echo ""
    bash /app/test-matter-connection.sh
    echo ""
fi

go2rtc -config /app/go2rtc.yaml &
GO2RTC_PID=$!

sleep 3

if ! kill -0 $GO2RTC_PID 2>/dev/null; then
    echo "ERROR: go2rtc failed to start"
    exit 1
fi

echo "go2rtc started successfully (PID: $GO2RTC_PID)"

echo "Starting Matter camera bridge..."
exec /app/matter-camera-bridge
