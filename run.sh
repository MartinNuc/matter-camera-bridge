#!/usr/bin/env bash
set -e

echo "Starting Matter 1.5 Virtual Camera Bridge..."

# Read YouTube URL from add-on options
YOUTUBE_URL=$(jq -r '.youtube_url // "https://www.youtube.com/watch?v=jfKfPfyJRdk"' /data/options.json)
echo "Using YouTube URL: $YOUTUBE_URL"

# Generate go2rtc.yaml with the configured YouTube URL
cat > /tmp/go2rtc.yaml <<EOF
streams:
  youtube_stream:
    - exec:bash -c 'URL=\$(yt-dlp -f best -g "$YOUTUBE_URL" | head -1); ffmpeg -re -i "\$URL" -c:v libx264 -preset ultrafast -tune zerolatency -profile:v baseline -level 3.0 -pix_fmt yuv420p -g 30 -b:v 2M -c:a aac -b:a 128k -ar 48000 -f rtsp {output}'

api:
  listen: ":1984"

webrtc:
  listen: ":8555"
  candidates:
    - stun:stun.l.google.com:19302
EOF

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

go2rtc -config /tmp/go2rtc.yaml &
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
echo "Using GStreamer test video source (no physical camera required)"
exec /app/matter-camera-bridge --discriminator 3841 --passcode 20202021 --secured-device-port 5542 --KVS /tmp/chip_kvs_camera --camera-test-videosrc --camera-test-audiosrc
