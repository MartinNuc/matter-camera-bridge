#!/bin/bash
set -e

echo "Copying pre-built Matter Camera App..."

cd /var/connectedhomeip

echo "Checking for pre-built binary..."
ls -lh out/camera-app/chip-camera-app

echo ""
echo "Copying binary to /app..."
cp out/camera-app/chip-camera-app /app/matter-camera-bridge
chmod +x /app/matter-camera-bridge

echo ""
echo "Camera app ready!"
ls -lh /app/matter-camera-bridge
