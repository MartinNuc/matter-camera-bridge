#!/usr/bin/env bash
set -e

echo "Starting Matter 1.5 Virtual Camera Bridge..."

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
