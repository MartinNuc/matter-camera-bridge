#include <app-common/zap-generated/ids/Attributes.h>
#include <app-common/zap-generated/ids/Clusters.h>
#include <app/ConcreteAttributePath.h>
#include <app/server/Server.h>
#include <credentials/DeviceAttestationCredsProvider.h>
#include <credentials/examples/DeviceAttestationCredsExample.h>
#include <lib/core/CHIPError.h>
#include <lib/support/logging/CHIPLogging.h>
#include <platform/CHIPDeviceLayer.h>

#include "VirtualCameraDevice.h"

using namespace chip;
using namespace chip::app;
using namespace chip::DeviceLayer;

namespace {
VirtualCameraDevice * gCameraDevice = nullptr;
}

void ApplicationInit()
{
    ChipLogProgress(AppServer, "Matter Virtual Camera Bridge Starting...");
    
    gCameraDevice = new VirtualCameraDevice();
    
    CHIP_ERROR err = gCameraDevice->Init();
    if (err != CHIP_NO_ERROR)
    {
        ChipLogError(AppServer, "Failed to initialize camera device: %s", ErrorStr(err));
        delete gCameraDevice;
        gCameraDevice = nullptr;
        return;
    }
    
    ChipLogProgress(AppServer, "Virtual Camera Device initialized successfully");
}

void ApplicationShutdown()
{
    ChipLogProgress(AppServer, "Shutting down Matter Virtual Camera Bridge...");
    
    if (gCameraDevice != nullptr)
    {
        delete gCameraDevice;
        gCameraDevice = nullptr;
    }
}

int main(int argc, char * argv[])
{
    CHIP_ERROR err = CHIP_NO_ERROR;

    err = Platform::MemoryInit();
    SuccessOrExit(err);

    err = PlatformMgr().InitChipStack();
    SuccessOrExit(err);

    err = Server::GetInstance().Init();
    SuccessOrExit(err);

    Credentials::SetDeviceAttestationCredentialsProvider(Credentials::Examples::GetExampleDACProvider());

    ApplicationInit();

    ChipLogProgress(AppServer, "Matter Camera Bridge is ready for commissioning");
    ChipLogProgress(AppServer, "Scan QR code or use manual pairing code to commission");

    PlatformMgr().RunEventLoop();

exit:
    ApplicationShutdown();
    
    Server::GetInstance().Shutdown();
    PlatformMgr().Shutdown();
    Platform::MemoryShutdown();

    return (err == CHIP_NO_ERROR) ? 0 : 1;
}
