# Source Code Directory - NOT IN USE

**⚠️ IMPORTANT: The code in this directory is NOT currently compiled or used.**

## Current Architecture

The add-on uses the **official pre-built `chip-camera-app`** from the connectedhomeip SDK, not custom code.

### What's actually used:
- `/app/matter-camera-bridge` - Official chip-camera-app binary from connectedhomeip
- `/app/matter-light` - Official chip-lighting-app binary from connectedhomeip
- `go2rtc` - Provides RTSP streaming for Frigate (independent of Matter)

### Files in this directory (NOT USED):
- `VirtualCameraDevice.cpp/.h` - Custom camera device wrapper (dead code)
- `Go2RtcTransport.cpp/.h` - Custom go2rtc WebRTC bridge (dead code)
- `main.cpp` - Custom main entry point (dead code)

## Why this code exists

This code was an initial attempt to create a custom bridge between go2rtc and Matter. However, the official chip-camera-app from connectedhomeip already provides:
- Full WebRTC Transport Provider cluster implementation
- CameraAVStreamManagement cluster
- GStreamer-based video capture and streaming
- Complete Matter camera device type support

## Future Integration

To integrate go2rtc's RTSP stream with the Matter camera (instead of test patterns), you would need to:
1. Use `v4l2loopback` to create a virtual `/dev/video0` device
2. Feed go2rtc's output into the virtual device
3. Configure chip-camera-app to use `/dev/video0`

Or alternatively, modify the official camera-app to accept RTSP sources directly.
