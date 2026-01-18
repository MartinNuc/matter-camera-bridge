# Matter 1.5 Virtual Camera Bridge

A Home Assistant Add-on that creates a Matter 1.5 compliant virtual camera device. This add-on transcodes video sources (YouTube URLs or local MP4 files) into WebRTC streams compatible with Apple Home, Google Home, and Home Assistant.

## Features

- **Matter 1.5 Compliance**: Native Matter camera device type using official connectedhomeip SDK
- **WebRTC Streaming**: Low-latency H.264/Opus streams via go2rtc
- **Dual Source Support**: YouTube live streams or local video files
- **Universal Compatibility**: Works with Apple Home, Google Home, and Home Assistant
- **Zero-Latency Tuning**: Optimized FFmpeg settings for fast Matter handshake
- **Native C++ Implementation**: Built on official Project CHIP (connectedhomeip) SDK

## Tech Stack

- **Language**: C++ (with connectedhomeip SDK v1.5.0.0)
- **Matter Stack**: connectedhomeip (official Matter SDK with native camera support)
- **Media Engine**: go2rtc (WebRTC signaling and distribution)
- **Transcoding**: FFmpeg (H.264 baseline profile + Opus audio)
- **Extraction**: yt-dlp (YouTube stream fetching)
- **Build System**: GN + Ninja

## Installation

### Method 1: Home Assistant Add-on Store (Recommended)

1. Navigate to **Settings** → **Add-ons** → **Add-on Store**
2. Click the **⋮** menu (top right) → **Repositories**
3. Add this repository URL: `https://github.com/yourusername/matter-camera-addon`
4. Find "Matter 1.5 Virtual Camera" in the store and click **Install**

### Method 2: Manual Installation

1. Copy this entire folder to `/addons/matter-camera-addon/` in your Home Assistant config directory
2. Restart Home Assistant
3. Navigate to **Settings** → **Add-ons** → **Local Add-ons**
4. Install "Matter 1.5 Virtual Camera"

## Configuration

### Add-on Options

```yaml
video_source: youtube  # or "file"
youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
video_file: "video.mp4"  # Relative to /share/ directory
matter_vendor_id: 65521
matter_product_id: 32768
```

### Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `video_source` | `youtube` \| `file` | `youtube` | Video source type |
| `youtube_url` | string | Sample URL | YouTube video or live stream URL |
| `video_file` | string | `video.mp4` | Filename in `/share/` directory |
| `matter_vendor_id` | int | 65521 | Matter vendor ID (0xFFF1 = test) |
| `matter_product_id` | int | 32768 | Matter product ID |

### Using Local Video Files

1. Place your `.mp4` file in Home Assistant's `/share/` directory
2. Set `video_source: file`
3. Set `video_file: your-video.mp4`
4. Restart the add-on

## Usage

### 1. Start the Add-on

After installation and configuration:
1. Click **Start** on the add-on page
2. Check the **Log** tab for the QR code and pairing information

### 2. Commission the Device

The add-on will display:
- **QR Code** (ASCII art in logs)
- **Manual Pairing Code** (numeric code)
- **QR Code String** (for manual entry)

#### Apple Home

1. Open the **Home** app on iPhone/iPad
2. Tap **+** → **Add Accessory**
3. Scan the QR code from the add-on logs
4. Follow the pairing prompts

#### Google Home

1. Open the **Google Home** app
2. Tap **+** → **Set up device** → **Works with Matter**
3. Scan the QR code or enter the manual code
4. Complete the setup flow

#### Home Assistant

1. Navigate to **Settings** → **Devices & Services**
2. Click **+ Add Integration** → **Matter**
3. Scan the QR code or enter the pairing code

### 3. View the Stream

Once paired, the camera will appear as a native device in your smart home platform. The stream will automatically start when you open the camera view.

## Architecture

```
┌─────────────────┐
│  YouTube / File │
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ yt-dlp  │ (YouTube only)
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │ FFmpeg  │ (Transcode to H.264/Opus)
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │ go2rtc  │ (WebRTC Server)
    └────┬────┘
         │
         ▼
┌────────────────────────┐
│  Matter Bridge (C++)   │
│  - connectedhomeip SDK │
│  - Camera Device       │
│  - WebRTC Transport    │
│  - Go2RtcTransport     │
└────────┬───────────────┘
         │
         ▼
┌────────────────┐
│ Matter Network │
│ (UDP Port 5540)│
└────────┬───────┘
         │
         ▼
┌────────────────────────┐
│ Apple/Google/HA Client │
└────────────────────────┘
```

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 5540 | UDP | Matter protocol communication |
| 1984 | TCP | go2rtc HTTP API |
| 8555 | UDP | WebRTC ICE candidates |

## Troubleshooting

### Stream Timeout During Pairing

**Symptom**: Matter pairing fails or times out

**Solution**: 
- Ensure FFmpeg is using `-tune zerolatency` (already configured)
- Check that go2rtc is running: `curl http://localhost:1984/api/streams`
- Verify network connectivity between devices

### YouTube Stream Not Working

**Symptom**: "Failed to extract stream" errors

**Solution**:
- Verify the YouTube URL is accessible
- Check yt-dlp version: `yt-dlp --version`
- Try a different video or live stream
- Some streams may be geo-restricted

### Local File Not Found

**Symptom**: "No such file or directory" errors

**Solution**:
- Ensure the file is in `/share/` directory
- Check file permissions (should be readable)
- Verify the filename matches exactly (case-sensitive)

### Matter Pairing Code Not Showing

**Symptom**: No QR code in logs

**Solution**:
- Check add-on logs for errors
- Restart the add-on
- Ensure port 5540/UDP is not in use by another service

## Development

### Building Locally

The project uses the official connectedhomeip SDK and requires a Docker build environment:

```bash
cd matter-camera
docker build -t matter-camera .
```

### Building Without Docker (Advanced)

```bash
# Install dependencies (Ubuntu 22.04)
sudo apt-get install git gcc g++ pkg-config libssl-dev \
  libdbus-1-dev libglib2.0-dev libavahi-client-dev \
  ninja-build python3-venv python3-dev cmake curl \
  ffmpeg libavformat-dev libavcodec-dev libavutil-dev \
  libcurl4-openssl-dev

# Clone connectedhomeip SDK
git clone --depth 1 --branch v1.5.0.0 \
  https://github.com/project-chip/connectedhomeip.git /var/connectedhomeip
cd /var/connectedhomeip
./scripts/checkout_submodules.py --shallow --platform linux

# Build the camera bridge
cd /path/to/matter-camera
./build.sh
```

### Testing

```bash
# Check go2rtc status
curl http://localhost:1984/api/streams

# Test WebRTC offer
curl -X POST http://localhost:1984/api/webrtc?src=matter_stream \
  -H "Content-Type: application/sdp" \
  -d @offer.sdp

# View Matter logs
docker logs -f matter-camera
```

## Technical Details

### FFmpeg Settings

The add-on uses optimized FFmpeg parameters for Matter compatibility:

- **Video Codec**: H.264 baseline profile, level 3.0
- **Pixel Format**: yuv420p (universal compatibility)
- **Bitrate**: 2 Mbps (adaptive)
- **GOP Size**: 30 frames (1 second at 30fps)
- **Tuning**: zerolatency (minimal buffering)
- **Audio Codec**: Opus at 128 kbps, 48 kHz stereo

### Matter Device Type

- **Device Type ID**: 0x002C (Camera)
- **Vendor ID**: 0xFFF1 (Test vendor, configurable)
- **Product ID**: 0x8000 (Configurable)
- **SDK Version**: connectedhomeip v1.5.0.0

### Matter 1.5 Camera Clusters

The implementation uses official Matter 1.5 camera clusters:

- **CameraAvStreamManagement**: Stream configuration and control
- **PushAvStreamTransport**: Push-based video streaming
- **WebRTCTransportProvider**: WebRTC signaling and transport
- **CameraAvSettingsUserLevelManagement**: Camera settings (PTZ, etc.)
- **ZoneManagement**: Motion detection zones

### WebRTC Signaling Flow

1. Matter controller sends SDP Offer to camera device
2. VirtualCameraDevice receives offer via Matter protocol
3. Go2RtcTransport forwards offer to go2rtc API
4. go2rtc processes offer and returns SDP Answer
5. Answer relayed back through Matter to controller
6. ICE candidates exchanged via go2rtc `/api/ice`
7. WebRTC stream established

### Source Code Structure

```
src/
├── main.cpp                    # Entry point, Matter server initialization
├── VirtualCameraDevice.h/cpp   # Camera device implementation
└── Go2RtcTransport.h/cpp       # WebRTC transport via go2rtc
```

## Known Limitations

- **Single Stream**: One camera instance per add-on
- **H.264 Only**: No HEVC/VP9 support (Matter spec limitation)
- **No Audio Backchannel**: Two-way audio not implemented yet
- **Build Time**: Initial Docker build takes 15-30 minutes (SDK compilation)

## License

MIT License - See LICENSE file for details

## Credits

- **connectedhomeip**: Official Matter SDK by Connectivity Standards Alliance (CSA)
- **Project CHIP**: The foundation of Matter protocol
- **go2rtc**: AlexxIT's excellent WebRTC server
- **yt-dlp**: YouTube stream extraction
- **FFmpeg**: Universal media transcoding

## Support

For issues and feature requests, please open an issue on GitHub:
https://github.com/yourusername/matter-camera-addon/issues
