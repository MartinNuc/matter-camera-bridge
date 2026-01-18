#include "Go2RtcTransport.h"
#include <lib/support/logging/CHIPLogging.h>
#include <curl/curl.h>
#include <fstream>
#include <sstream>

using namespace chip;

namespace {
constexpr const char * kGo2RtcApiUrl = "http://localhost:1984";
}

static size_t WriteCallback(void * contents, size_t size, size_t nmemb, void * userp)
{
    ((std::string *)userp)->append((char *)contents, size * nmemb);
    return size * nmemb;
}

Go2RtcTransport::Go2RtcTransport() : 
    mStreamSource(""),
    mIsYouTube(false),
    mInitialized(false)
{
}

Go2RtcTransport::~Go2RtcTransport()
{
}

CHIP_ERROR Go2RtcTransport::Init()
{
    ChipLogProgress(AppServer, "Initializing go2rtc transport");
    
    curl_global_init(CURL_GLOBAL_DEFAULT);
    
    ReturnErrorOnFailure(ConfigureGo2Rtc());
    
    ReturnErrorOnFailure(StartStream());
    
    mInitialized = true;
    
    ChipLogProgress(AppServer, "go2rtc transport initialized");
    
    return CHIP_NO_ERROR;
}

void Go2RtcTransport::SetStreamSource(const std::string & source, bool isYouTube)
{
    mStreamSource = source;
    mIsYouTube = isYouTube;
}

CHIP_ERROR Go2RtcTransport::ConfigureGo2Rtc()
{
    ChipLogProgress(AppServer, "Configuring go2rtc stream");
    
    std::string streamCmd;
    
    if (mIsYouTube)
    {
        streamCmd = "exec:yt-dlp -f best -g \"" + mStreamSource + 
                   "\" | xargs -I {} ffmpeg -re -i {} "
                   "-c:v libx264 -preset ultrafast -tune zerolatency "
                   "-profile:v baseline -level 3.0 -pix_fmt yuv420p "
                   "-g 30 -keyint_min 30 -sc_threshold 0 "
                   "-b:v 2M -maxrate 2M -bufsize 4M "
                   "-c:a libopus -b:a 128k -ar 48000 -ac 2 "
                   "-f rtsp -rtsp_transport tcp rtsp://localhost:8554/matter_stream";
    }
    else
    {
        streamCmd = "exec:ffmpeg -re -stream_loop -1 -i /share/" + mStreamSource + 
                   " -c:v libx264 -preset ultrafast -tune zerolatency "
                   "-profile:v baseline -level 3.0 -pix_fmt yuv420p "
                   "-g 30 -keyint_min 30 -sc_threshold 0 "
                   "-b:v 2M -maxrate 2M -bufsize 4M "
                   "-c:a libopus -b:a 128k -ar 48000 -ac 2 "
                   "-f rtsp -rtsp_transport tcp rtsp://localhost:8554/matter_stream";
    }
    
    std::ofstream configFile("/etc/go2rtc.yaml");
    if (!configFile.is_open())
    {
        ChipLogError(AppServer, "Failed to write go2rtc config");
        return CHIP_ERROR_INTERNAL;
    }
    
    configFile << "streams:\n";
    configFile << "  matter_stream:\n";
    configFile << "    - \"" << streamCmd << "\"\n";
    configFile << "\n";
    configFile << "api:\n";
    configFile << "  listen: \":1984\"\n";
    configFile << "\n";
    configFile << "webrtc:\n";
    configFile << "  listen: \":8555\"\n";
    configFile << "  candidates:\n";
    configFile << "    - stun:stun.l.google.com:19302\n";
    
    configFile.close();
    
    ChipLogProgress(AppServer, "go2rtc configuration written");
    
    return CHIP_NO_ERROR;
}

CHIP_ERROR Go2RtcTransport::StartStream()
{
    ChipLogProgress(AppServer, "Stream will be started by go2rtc on first request");
    return CHIP_NO_ERROR;
}

CHIP_ERROR Go2RtcTransport::HandleWebRtcOffer(const std::string & offer, std::string & answer)
{
    ChipLogProgress(AppServer, "Handling WebRTC offer");
    
    std::string url = std::string(kGo2RtcApiUrl) + "/api/webrtc?src=matter_stream";
    
    answer = HttpPost(url, offer, "application/sdp");
    
    if (answer.empty())
    {
        ChipLogError(AppServer, "Failed to get WebRTC answer from go2rtc");
        return CHIP_ERROR_INTERNAL;
    }
    
    ChipLogProgress(AppServer, "Received WebRTC answer from go2rtc");
    
    return CHIP_NO_ERROR;
}

CHIP_ERROR Go2RtcTransport::HandleIceCandidate(const std::string & candidate)
{
    ChipLogProgress(AppServer, "Handling ICE candidate");
    
    std::string url = std::string(kGo2RtcApiUrl) + "/api/ice";
    std::string payload = "{\"candidate\":\"" + candidate + "\"}";
    
    HttpPost(url, payload, "application/json");
    
    return CHIP_NO_ERROR;
}

std::string Go2RtcTransport::HttpPost(const std::string & url, const std::string & data, const std::string & contentType)
{
    CURL * curl;
    CURLcode res;
    std::string response;
    
    curl = curl_easy_init();
    if (!curl)
    {
        ChipLogError(AppServer, "Failed to initialize CURL");
        return "";
    }
    
    struct curl_slist * headers = nullptr;
    std::string contentTypeHeader = "Content-Type: " + contentType;
    headers = curl_slist_append(headers, contentTypeHeader.c_str());
    
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data.c_str());
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);
    
    res = curl_easy_perform(curl);
    
    if (res != CURLE_OK)
    {
        ChipLogError(AppServer, "CURL request failed: %s", curl_easy_strerror(res));
    }
    
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    
    return response;
}
