#!/bin/bash

echo "=========================================="
echo "go2rtc Video Stream Test"
echo "=========================================="
echo ""
echo "This will test the video streaming pipeline"
echo "without the Matter bridge."
echo ""

# Create local bin directory
mkdir -p ./bin
export PATH="$(pwd)/bin:$PATH"

# Check if go2rtc is installed
if [ ! -f ./bin/go2rtc ]; then
    echo "Downloading go2rtc..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - detect architecture
        if [[ $(uname -m) == "arm64" ]]; then
            curl -fsSL https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_mac_arm64.zip -o ./bin/go2rtc.zip
        else
            curl -fsSL https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_mac_amd64.zip -o ./bin/go2rtc.zip
        fi
        unzip -q -o ./bin/go2rtc.zip -d ./bin/
        rm ./bin/go2rtc.zip
        chmod +x ./bin/go2rtc
    else
        # Linux
        curl -fsSL https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_amd64 -o ./bin/go2rtc
        chmod +x ./bin/go2rtc
    fi
    echo "✓ go2rtc downloaded"
fi

# Check if yt-dlp is installed
if [ ! -f ./bin/yt-dlp ]; then
    echo "Downloading yt-dlp..."
    curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ./bin/yt-dlp
    chmod a+rx ./bin/yt-dlp
    echo "✓ yt-dlp downloaded"
fi

echo ""
echo "Starting go2rtc with test configuration..."
echo ""

./bin/go2rtc -config test-go2rtc.yaml &
GO2RTC_PID=$!

sleep 3

if ! kill -0 $GO2RTC_PID 2>/dev/null; then
    echo "ERROR: go2rtc failed to start"
    exit 1
fi

echo "✓ go2rtc started successfully (PID: $GO2RTC_PID)"
echo ""
echo "=========================================="
echo "Stream is ready!"
echo "=========================================="
echo ""
echo "Open in your browser:"
echo "  http://localhost:1984/"
echo ""
echo "Then click on 'test_stream' to view the video"
echo ""
echo "Or test WebRTC directly:"
echo "  http://localhost:1984/stream.html?src=test_stream"
echo ""
echo "API endpoints:"
echo "  Streams: http://localhost:1984/api/streams"
echo "  WebRTC:  http://localhost:1984/api/webrtc?src=test_stream"
echo ""
echo "Press Ctrl+C to stop..."
echo ""

trap "kill $GO2RTC_PID 2>/dev/null; exit" INT TERM

wait $GO2RTC_PID
