// Video support with XAML
// Microsoft Surface and Phone using Media Foundation

// Copyright (c) 2014, Microsoft Open Technologies, Inc. 
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
// - Redistributions of source code must retain the above copyright notice, 
//   this list of conditions and the following disclaimer.
// - Redistributions in binary form must reproduce the above copyright notice, 
//   this list of conditions and the following disclaimer in the documentation 
//   and/or other materials provided with the distribution.
// - Neither the name of Microsoft Open Technologies, Inc. nor the names 
//   of its contributors may be used to endorse or promote products derived 
//   from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "video.h"

#include <ppl.h>
#include <ppltasks.h>
#include <concrt.h>
#include <agile.h>

#include <atomic>
#include <future>
#include <vector>


using namespace ::concurrency;
using namespace ::Windows::Foundation;
using namespace ::std;

using namespace Microsoft::WRL;
using namespace Windows::Media::Devices;
using namespace Windows::Media::MediaProperties;
using namespace Windows::Media::Capture;
using namespace Windows::UI::Xaml::Media::Imaging;
using namespace Windows::Devices::Enumeration;

#include "CaptureFrameGrabber/CaptureFrameGrabber.h"

// pull in MF libs (this has to be somewhere in the project)
#pragma comment(lib, "mfplat")
#pragma comment(lib, "mf")
#pragma comment(lib, "mfuuid")
#pragma comment(lib, "Shlwapi")

#include "../../../modules/highgui/src/cap_winrt_highgui.hpp"


Video::Video() {
}

Video &Video::get() {
    static Video v;
    return v;
}

// initGrabber(0, 640, 480);


bool Video::initGrabber(int device, int w, int h)
{
    // std::atomic<bool> ready(false);

    width = w;
    height = h;
    bytesPerPixel = 3;
    bGrabberInited = false;

    //m_frontBuffer = std::unique_ptr<ofPixels>(new ofPixels);
    //m_backBuffer = std::unique_ptr<ofPixels>(new ofPixels);
    //m_frontBuffer->allocate(w, h, bytesPerPixel);
    //m_backBuffer->allocate(w, h, bytesPerPixel);
    frameCounter = 0;
    currentFrame = 0;

    //if (bChooseDevice){
    //    bChooseDevice = false;
    //    // ofLogNotice("ofWinrtVideoGrabber") << "initGrabber(): choosing " << m_deviceID;
    //}
    //else {
    //    m_deviceID = 0;
    //}

    //if (!m_devices.Get())
    //{
    //    listDevicesTask();      // blocking
    //    if (!m_devices.Get())
    //    {
    //        // ofLogError("ofWinrtVideoGrabber") << "no video devices are available";
    //        return false;
    //    }
    //}

    m_deviceID = device;

    create_task(DeviceInformation::FindAllAsync(DeviceClass::VideoCapture))
        .then([this](task<DeviceInformationCollection^> findTask)
    {
        m_devices = findTask.get();

        // got any devices?
        if (m_devices.Get()->Size == 0) return false;

        auto devInfo = m_devices.Get()->GetAt(m_deviceID);

        auto settings = ref new MediaCaptureInitializationSettings();
        settings->StreamingCaptureMode = StreamingCaptureMode::Video; // Video-only capture
        settings->VideoDeviceId = devInfo->Id;

        auto location = devInfo->EnclosureLocation;
        if (location != nullptr && location->Panel == Windows::Devices::Enumeration::Panel::Front)
        {
            bFlipImageX = true;
        }

        m_capture = ref new MediaCapture();
        create_task(m_capture->InitializeAsync(settings)).then([this](){

            auto props = safe_cast<VideoEncodingProperties^>(m_capture->VideoDeviceController->GetMediaStreamProperties(MediaStreamType::VideoPreview));
            // props->Subtype = MediaEncodingSubtypes::Rgb24;   // for 24 bpp
            props->Subtype = MediaEncodingSubtypes::Bgra8;      // for test
            props->Width = width;
            props->Height = height;

            return ::Media::CaptureFrameGrabber::CreateAsync(m_capture.Get(), props);

        }).then([this](::Media::CaptureFrameGrabber^ frameGrabber)
        {
            m_frameGrabber = frameGrabber;
            bGrabberInited = true;
            //ready = true;
            _GrabFrameAsync(frameGrabber);
            //ofAddListener(ofEvents().appResume, this, &ofWinrtVideoGrabber::appResume, ofEventOrder::OF_EVENT_ORDER_AFTER_APP);
        });

        return true;
    });


    // wait for async task to complete
    //int count = 0;
    //while (!ready)
    //{
    //    count++;
    //}

    return true;
}

void Video::_GrabFrameAsync(::Media::CaptureFrameGrabber^ frameGrabber)
{
    create_task(frameGrabber->GetFrameAsync()).then([this, frameGrabber](const ComPtr<IMF2DBuffer2>& buffer)
    {
        auto bitmap = ref new WriteableBitmap(width, height);

        CHK(buffer->ContiguousCopyTo(GetData(bitmap->PixelBuffer), bitmap->PixelBuffer->Capacity));

        unsigned long length;
        CHK(buffer->GetContiguousLength(&length));
        bitmap->PixelBuffer->Length = length;

        m_cvImage->Source = bitmap;

        // notify frame is ready
        HighguiBridge::get().bIsFrameNew = true;
        //{
        //    unique_lock<mutex> lck(HighguiBridge::get().frameReadyMutex);
        //    HighguiBridge::get().frameReadyEvent.notify_one();
        //}

        // loss of camera device & restart is not yet handled

        _GrabFrameAsync(frameGrabber);
    }, task_continuation_context::use_current());
}

#if 0
void ofWinrtVideoGrabber::_GrabFrameAsync(Media::CaptureFrameGrabber^ frameGrabber)
{
    create_task(frameGrabber->GetFrameAsync()).then([this, frameGrabber](const ComPtr<IMF2DBuffer2>& buffer)
    {
        // do the RGB swizzle while copying the pixels from the IMF2DBuffer2
        BYTE *pbScanline;
        LONG plPitch;
        unsigned int numBytes = width * bytesPerPixel;
        CHK(buffer->Lock2D(&pbScanline, &plPitch));

        if (bFlipImageX)
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            uint8_t* buf = reinterpret_cast<uint8_t*>(m_backBuffer->getPixels());

            for (unsigned int row = 0; row < height; row++)
            {
                unsigned int i = 0;
                unsigned int j = numBytes - 1;

                while (i < numBytes)
                {
                    // reverse the scan line
                    // as a side effect this also swizzles R and B channels
                    buf[j--] = pbScanline[i++];
                    buf[j--] = pbScanline[i++];
                    buf[j--] = pbScanline[i++];
                }
                pbScanline += plPitch;
                buf += numBytes;
            }
        }
        else
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            uint8_t* buf = reinterpret_cast<uint8_t*>(m_backBuffer->getPixels());

            for (unsigned int row = 0; row < height; row++)
            {
                for (unsigned int i = 0; i < numBytes; i += bytesPerPixel)
                {
                    // swizzle the R and B values (BGR to RGB)
                    buf[i] = pbScanline[i + 2];
                    buf[i + 1] = pbScanline[i + 1];
                    buf[i + 2] = pbScanline[i];
                }
                pbScanline += plPitch;
                buf += numBytes;
            }
        }
        CHK(buffer->Unlock2D());

        frameCounter++;

        if (bGrabberInited)
        {
            _GrabFrameAsync(frameGrabber);
        }
    }, task_continuation_context::use_current());
}

#endif


bool Video::listDevicesTask()
{
    std::atomic<bool> ready(false);

    auto settings = ref new MediaCaptureInitializationSettings();

    //vector <int> devices;

    create_task(DeviceInformation::FindAllAsync(DeviceClass::VideoCapture))
        .then([this, &ready](task<DeviceInformationCollection^> findTask)
    {
        m_devices = findTask.get();

        for (size_t i = 0; i < m_devices->Size; i++)
        {
            // ofVideoDevice deviceInfo;
            auto d = m_devices->GetAt(i);
            //deviceInfo.bAvailable = true;
            //deviceInfo.deviceName = PlatformStringToString(d->Name);
            //deviceInfo.hardwareName = deviceInfo.deviceName;
            // devices.push_back(deviceInfo);
        }

        ready = true;
    });

    // wait for async task to complete
    int count = 0;
    while (!ready)
    {
        count++;
    }

    return true;
}


bool Video::listDevices()
{
    // synchronous version of listing video devices on WinRT
    std::future<bool> result = std::async(std::launch::async, &Video::listDevicesTask, this);
    return result.get();
}