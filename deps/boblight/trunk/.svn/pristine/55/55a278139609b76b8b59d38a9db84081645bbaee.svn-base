/*
 * boblight
 * Copyright (C) Bob  2012
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

#include "config.h"
#include "deviceibelight.h"
#include "util/log.h"
#include "util/misc.h"
#include "util/timeutils.h"

#define IBE_VID       0x1506
#define IBE_PID       0x0020
#define IBE_INTERFACE 0
#define IBE_ENDPOINT  1
#define IBE_TIMEOUT   100

CDeviceiBeLight::CDeviceiBeLight(CClientsHandler& clients) : CDeviceUsb(clients)
{
  m_usbcontext = NULL;
  m_devicehandle = NULL;
  m_chanbuffer = NULL;
}

void CDeviceiBeLight::Sync()
{
  if (m_allowsync)
    m_timer.Signal();
}

bool CDeviceiBeLight::SetupDevice()
{
  int error;
  if ((error = libusb_init(&m_usbcontext)) != LIBUSB_SUCCESS)
  {
    LogError("%s: error setting up usb context, error:%i %s", m_name.c_str(), error, UsbErrorName(error));
    m_usbcontext = NULL;
    return false;
  }

  if (m_debug)
    libusb_set_debug(m_usbcontext, 3);

  libusb_device** devicelist;
  libusb_device*  device = NULL;
  ssize_t         nrdevices = libusb_get_device_list(m_usbcontext, &devicelist);

  for (ssize_t i = 0; i < nrdevices; i++)
  {
    libusb_device_descriptor descriptor;
    error = libusb_get_device_descriptor(devicelist[i], &descriptor);
    if (error != LIBUSB_SUCCESS)
    {
      LogError("%s: error getting device descriptor for device %zi, error %i %s", m_name.c_str(), i, error, UsbErrorName(error));
      continue;
    }

    //try to find a usb device with the iBeLight vendor and product ID
    if (descriptor.idVendor == IBE_VID && descriptor.idProduct == IBE_PID)
    {
      int busnr = libusb_get_bus_number(devicelist[i]);
      int address = libusb_get_device_address(devicelist[i]);

      bool use = false;

      //if a custom bus and/or address is set, use only that
      //-1 for m_busnr and m_address means use any
      if (device == NULL && (m_busnumber == -1 || m_busnumber == busnr) && (m_deviceaddress == -1 || m_deviceaddress == address))
      {
        device = devicelist[i];
        use = true;
      }

      Log("%s found iBeLight on bus %i address %i%s", m_name.c_str(), busnr, address, use ? ", using" : "");
    }
  }

  if (!device)
  {
    std::string buserror;
    if (m_busnumber != -1 || m_deviceaddress != -1)
    {
      buserror = " on";
      if (m_busnumber != -1)
        buserror += " bus " + ToString(m_busnumber);
      if (m_deviceaddress != -1)
        buserror += " address " + ToString(m_deviceaddress);
    }

    LogError("%s: no iBeLight device with vid %04x and pid %04x found%s", m_name.c_str(), IBE_VID, IBE_PID, buserror.c_str());
    libusb_free_device_list(devicelist, 1);
    return false;
  }

  error = libusb_open(device, &m_devicehandle);
  libusb_free_device_list(devicelist, 1);
  if (error != LIBUSB_SUCCESS)
  {
    LogError("%s: error opening device, error %i %s", m_name.c_str(), error, UsbErrorName(error));
    return false;
  }

  if ((error = libusb_claim_interface(m_devicehandle, IBE_INTERFACE)) != LIBUSB_SUCCESS)
  {
    LogError("%s: error claiming interface %i, error:%i %s", m_name.c_str(), IBE_INTERFACE, error, UsbErrorName(error));
    return false;
  }

  m_chanbuffer= new uint8_t[m_channels.size()];
  m_timer.SetInterval(m_interval);

  if (!SetPixelCount())
    return false;

  //set all leds to 0
  memset(m_chanbuffer, 0, m_channels.size());
  if (!SetColors())
    return false;

  return true;
}

bool CDeviceiBeLight::WriteOutput()
{
  //get the channel values from the clientshandler
  int64_t now = GetTimeUs();
  m_clients.FillChannels(m_channels, now, this);

  //put the values in the buffer
  for (int i = 0; i < m_channels.size(); i++)
  {
    int output = Round64((double)m_channels[i].GetValue(now) * 255.0);
    output = Clamp(output, 0, 255);

    m_chanbuffer[i] = output;
  }

  //write to the device
  if (!SetColors())
    return false;

  m_timer.Wait();

  return true;
}

void CDeviceiBeLight::CloseDevice()
{
  if (m_devicehandle)
  {
    if (m_chanbuffer)
    {
      //set all leds to 0
      memset(m_chanbuffer, 0, m_channels.size());
      SetColors();
      delete m_chanbuffer;
      m_chanbuffer = NULL;
    }

    libusb_release_interface(m_devicehandle, IBE_INTERFACE);
    libusb_close(m_devicehandle);
    m_devicehandle = NULL;
  }

  if (m_usbcontext)
  {
    libusb_exit(m_usbcontext);
    m_usbcontext = NULL;
  }
}

bool CDeviceiBeLight::SetPixelCount()
{
  //the iBeLight has each led mapped as a GRB pixel, boblightd will map one channel to one color of a pixel
  //set pixels so that pixels * 3 >= channels
  int pixels = m_channels.size() / 3;
  if (m_channels.size() % 3)
    pixels++;

  //0x80 = write setting, 0x80A0007000 = set pixel count
  uint8_t report[9] = {0x80, 0xA0, 0x00, 0x70, 0x00};
  //pixel count is a 32 bit int, big endian
  for (int i = 0; i < 4; i++)
    report[i + 5] = (pixels >> ((3 - i) * 8)) & 0xFF;

  int byteswritten, error;
  error = BulkTransfer(m_devicehandle, IBE_ENDPOINT | LIBUSB_ENDPOINT_OUT, report, sizeof(report), &byteswritten, IBE_TIMEOUT);

  if (error != LIBUSB_SUCCESS)
  {
    LogError("%s: error setting pixel count, error:%i %s", m_name.c_str(), error, UsbErrorName(error));
    return false;
  }

  return true;
}

//maximum nr of channels per report
#define MAXCHANS 60

bool CDeviceiBeLight::SetColors()
{
  //nr of reports needed for the nr of channels we have
  int reports = m_channels.size() / MAXCHANS;
  if (m_channels.size() % MAXCHANS)
    reports++;

  uint8_t report[64];
  for (int reportnr = 0; reportnr < reports; reportnr++)
  {
    report[0] = 0x90; //store color
    report[1] = reportnr; //store index

    int end = m_channels.size() - reportnr * MAXCHANS;
    if (end > MAXCHANS)
      end = MAXCHANS;

    for (int i = 0; i < end; i++)
      report[i + 2] = m_chanbuffer[reportnr * MAXCHANS + i];

    int byteswritten, error;
    error = BulkTransfer(m_devicehandle, IBE_ENDPOINT | LIBUSB_ENDPOINT_OUT, report, end + 2, &byteswritten, IBE_TIMEOUT);
    if (error != LIBUSB_SUCCESS)
    {
      LogError("%s: error storing colors, error:%i %s", m_name.c_str(), error, UsbErrorName(error));
      return false;
    }
  }

  report[0] = 0xA0; //set output to stored color
  int byteswritten, error;
  error = BulkTransfer(m_devicehandle, IBE_ENDPOINT | LIBUSB_ENDPOINT_OUT, report, 1, &byteswritten, IBE_TIMEOUT);
  if (error != LIBUSB_SUCCESS)
  {
    LogError("%s: error setting output to stored color, error:%i %s", m_name.c_str(), error, UsbErrorName(error));
    return false;
  }

  return true;
}

int CDeviceiBeLight::BulkTransfer(struct libusb_device_handle* dev_handle, unsigned char endpoint,
                      unsigned char* data, int length, int* transferred, unsigned int timeout)
{
  int returnv = libusb_bulk_transfer(dev_handle, endpoint, data, length, transferred, timeout);

  if (m_debug)
  {
    if ((endpoint & LIBUSB_ENDPOINT_IN) == LIBUSB_ENDPOINT_IN)
      printf("%s %i bytes read: ", m_name.c_str(), *transferred);
    else
      printf("%s %i bytes written: ", m_name.c_str(), *transferred);
      
    for (int i = 0; i < (*transferred < length ? *transferred : length); i++)
      printf("%02x ", data[i]);
    printf("\n");
  }

  return returnv;
}

const char* CDeviceiBeLight::UsbErrorName(int errcode)
{
#ifdef HAVE_LIBUSB_ERROR_NAME
  return libusb_error_name(errcode);
#else
  return "";
#endif
}

