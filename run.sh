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

echo ""
echo "Starting Matter light (port 5540, discriminator 3000)..."
/app/matter-light --discriminator 3000 --passcode 20202021 --KVS /tmp/chip_kvs_light &
LIGHT_PID=$!

sleep 2

echo ""
echo "Starting Matter camera (port 5542, discriminator 3841)..."
exec /app/matter-camera-bridge --discriminator 3841 --passcode 20202021 --secured-device-port 5542 --KVS /tmp/chip_kvs_camera
