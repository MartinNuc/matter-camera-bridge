#pragma once

#include <lib/core/CHIPError.h>
#include <string>

class Go2RtcTransport
{
public:
    Go2RtcTransport();
    ~Go2RtcTransport();

    chip::CHIP_ERROR Init();
    
    void SetStreamSource(const std::string & source, bool isYouTube);
    
    chip::CHIP_ERROR HandleWebRtcOffer(const std::string & offer, std::string & answer);
    
    chip::CHIP_ERROR HandleIceCandidate(const std::string & candidate);

private:
    std::string mStreamSource;
    bool mIsYouTube;
    bool mInitialized;
    
    chip::CHIP_ERROR ConfigureGo2Rtc();
    chip::CHIP_ERROR StartStream();
    
    std::string HttpPost(const std::string & url, const std::string & data, const std::string & contentType);
};
