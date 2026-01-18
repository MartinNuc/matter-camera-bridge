#include "VirtualCameraDevice.h"
#include <app/server/Server.h>
#include <lib/support/logging/CHIPLogging.h>
#include <fstream>
#include <json/json.h>

using namespace chip;
using namespace chip::app;
using namespace chip::DeviceLayer;

namespace {
constexpr EndpointId kCameraEndpoint = 1;
}

VirtualCameraDevice::VirtualCameraDevice() : 
    mEndpointId(kCameraEndpoint),
    mTransport()
{
}

VirtualCameraDevice::~VirtualCameraDevice()
{
}

CHIP_ERROR VirtualCameraDevice::Init()
{
    ChipLogProgress(AppServer, "Initializing Virtual Camera Device on endpoint %d", mEndpointId);
    
    ReturnErrorOnFailure(ConfigureStreamFromOptions());
    
    ReturnErrorOnFailure(mTransport.Init());
    
    ReturnErrorOnFailure(SetupCameraAttributes());
    
    ChipLogProgress(AppServer, "Virtual Camera Device initialized");
    
    return CHIP_NO_ERROR;
}

CHIP_ERROR VirtualCameraDevice::ConfigureStreamFromOptions()
{
    std::ifstream optionsFile("/data/options.json");
    if (!optionsFile.is_open())
    {
        ChipLogError(AppServer, "Could not open /data/options.json, using defaults");
        return CHIP_NO_ERROR;
    }
    
    Json::Value root;
    Json::CharReaderBuilder builder;
    std::string errors;
    
    if (!Json::parseFromStream(builder, optionsFile, &root, &errors))
    {
        ChipLogError(AppServer, "Failed to parse options.json: %s", errors.c_str());
        return CHIP_NO_ERROR;
    }
    
    std::string videoSource = root.get("video_source", "youtube").asString();
    std::string youtubeUrl = root.get("youtube_url", "").asString();
    std::string videoFile = root.get("video_file", "video.mp4").asString();
    
    ChipLogProgress(AppServer, "Video source: %s", videoSource.c_str());
    
    if (videoSource == "youtube")
    {
        ChipLogProgress(AppServer, "YouTube URL: %s", youtubeUrl.c_str());
        mTransport.SetStreamSource(youtubeUrl, true);
    }
    else
    {
        ChipLogProgress(AppServer, "Video file: %s", videoFile.c_str());
        mTransport.SetStreamSource(videoFile, false);
    }
    
    return CHIP_NO_ERROR;
}

CHIP_ERROR VirtualCameraDevice::SetupCameraAttributes()
{
    ChipLogProgress(AppServer, "Setting up camera attributes");
    
    return CHIP_NO_ERROR;
}
