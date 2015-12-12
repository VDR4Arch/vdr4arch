/*
 * boblight
 * Copyright (C) tim.helloworld 2013
 * 
 * boblight is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * boblight is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef CDEVICELIGHTPACK
#define CDEVICELIGHTPACK

#include "deviceusb.h"
#include <libusb-1.0/libusb.h>

#define LIGHTPACK_REPORT_SIZE 61

class CDeviceLightpack : public CDeviceUsb
{
  public:
    CDeviceLightpack(CClientsHandler& clients);
    void Sync();

  protected:

    bool SetupDevice();
    bool WriteOutput();
    void CloseDevice();
    bool DisableSmoothness();

    const char* UsbErrorName(int errcode);

    CSignalTimer          m_timer;
    libusb_context*       m_usbcontext;
    libusb_device_handle* m_devicehandle;
    unsigned char         m_buf[LIGHTPACK_REPORT_SIZE];
};

#endif //CDEVICELIGHTPACK
