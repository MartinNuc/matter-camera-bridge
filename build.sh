#!/bin/bash
set -e

echo "Copying pre-built Matter apps..."

cd /var/connectedhomeip

echo "Checking for pre-built camera app..."
ls -lh out/camera-app/chip-camera-app

echo ""
echo "Checking for pre-built lighting app..."
ls -lh out/lighting-app/chip-lighting-app

echo ""
echo "Checking for pre-built chip-tool..."
ls -lh out/chip-tool/chip-tool

echo ""
echo "Copying binaries to /app..."
cp out/camera-app/chip-camera-app /app/matter-camera-bridge
cp out/lighting-app/chip-lighting-app /app/matter-light
cp out/chip-tool/chip-tool /app/chip-tool
chmod +x /app/matter-camera-bridge /app/matter-light /app/chip-tool

echo ""
echo "Apps ready!"
ls -lh /app/matter-camera-bridge /app/matter-light /app/chip-tool
