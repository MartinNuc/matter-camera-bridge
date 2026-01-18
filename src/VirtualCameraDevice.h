#pragma once

#include <app/clusters/camera-av-stream-management-server/camera-av-stream-management-server.h>
#include <app/server/Server.h>
#include <lib/core/CHIPError.h>
#include <platform/CHIPDeviceLayer.h>

#include "Go2RtcTransport.h"

class VirtualCameraDevice
{
public:
    VirtualCameraDevice();
    ~VirtualCameraDevice();

    chip::CHIP_ERROR Init();
    
    Go2RtcTransport & GetTransport() { return mTransport; }

private:
    chip::EndpointId mEndpointId;
    Go2RtcTransport mTransport;
    
    chip::CHIP_ERROR SetupCameraAttributes();
    chip::CHIP_ERROR ConfigureStreamFromOptions();
};
