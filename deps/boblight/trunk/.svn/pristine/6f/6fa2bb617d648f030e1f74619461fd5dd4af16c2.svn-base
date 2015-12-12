/*
 * boblight
 * Copyright (C) Bob  2009 
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

#include "deviceltbl.h"
#include "util/log.h"
#include "util/misc.h"
#include "util/timeutils.h"

CDeviceLtbl::CDeviceLtbl(CClientsHandler& clients) : CDeviceRS232(clients)
{
  m_buff = NULL;
  m_isopened = false;
}

bool CDeviceLtbl::SetupDevice()
{
  m_timer.SetInterval(m_interval);

  if (!OpenSerialPort())
    return false;

  m_serialport.PrintToStdOut(m_debug); //print serial data to stdout when debug mode is on

  if (m_delayafteropen > 0)
    USleep(m_delayafteropen, &m_stop);

  //try to open the controller
  if (OpenController())
  {
    m_buff = new uint8_t[m_channels.size() * 2];
    return true;
  }

  return false;
}

bool CDeviceLtbl::WriteOutput()
{
  uint8_t prefix[4] = {0x55, 0xAA, 0x00, m_channels.size()};

  //get the channel values from the clienshandler
  int64_t now = GetTimeUs();
  m_clients.FillChannels(m_channels, now, this);

  //put channel values in the output buffer
  bool isused = false;
  for (int i = 0; i < m_channels.size(); i++)
  {
    if (m_channels[i].IsUsed())
      isused = true;

    //output value is 16 bit big endian
    int value = Clamp(Round32(m_channels[i].GetValue(now) * 65535.0f), 0, 65535);
    m_buff[i * 2 + 0] = (uint8_t)((value >> 8) & 0xFF);
    m_buff[i * 2 + 1] = (uint8_t)((value >> 0) & 0xFF);
  }

  if (isused)
  {
    if (!m_isopened) //if one of the channels is used, and the controller is not opened, open it
    {
      if (!OpenController())
        return false;
    }

    //write output to the serial port
    if (m_serialport.Write(prefix, 4) == -1 || m_serialport.Write(m_buff, m_channels.size() * 2) == -1)
    {
      LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
      return false;
    }
  }
  else if (m_isopened) //if no channels are used and the controller is opened, close it
  {
    if (!CloseController())
      return false;
  }
    
  m_timer.Wait(); //wait for the timer to signal us

  return true;
}

void CDeviceLtbl::CloseDevice()
{
  CloseController();

  if (m_buff)
  {
    delete m_buff;
    m_buff = NULL;
  }

  m_serialport.Close();
}

bool CDeviceLtbl::OpenController()
{
  uint8_t buff[512];
  uint8_t prefix[2]    = {0x55, 0xAA};
  uint8_t open[2]      = {0x83, 0x00};
  uint8_t getvalues[4] = {0x81, 0x02, 0x00, m_channels.size()};

  if (m_isopened)
    return true; //nothing to do here

  //send 255 times 0x55 for auto-baud, and 3 times 0xFF to get the rs232 sync back
  memset(buff, 0x55, 255);
  buff[255] = 0xFF;
  buff[256] = 0xFF;
  buff[257] = 0xFF;

  //write to the serial port
  if (m_serialport.Write(buff, 258) == -1 || m_serialport.Write(prefix, 2) == -1 || m_serialport.Write(open, 2) == -1)
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }

  //try to get the current values from the controller
  if (m_serialport.Write(prefix, 2) == -1 || m_serialport.Write(getvalues, 4) == -1)
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }

  //wait for the controller to send the prefix back
  if (!WaitForPrefix())
    return false;

  //read the startchannel and number of channels from the controller with a timeout of 1 second
  if (m_serialport.Read(buff, 2, 1000000) == -1)
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }

  int startchannel = buff[0];
  int nrchannels = buff[1];

  if (startchannel < 0 || nrchannels <= 0 || startchannel + nrchannels > (int)m_channels.size())
  {
    LogError("%s: %s sent gibberish, startchannel: %i, nrchannels: %i", m_name.c_str(), m_output.c_str(), startchannel, nrchannels);
    return false;
  }

  //read the channel values from the controller with a timeout of 1 second
  if (m_serialport.Read(buff, nrchannels * 2, 1000000) == -1)
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }

  //assign the channel values
  for (int i = startchannel; i < nrchannels; i++)
  {
    int value = (int)(buff[i * 2]) << 8;
    value |= (int)(buff[i * 2 + 1]);

    m_channels[i].SetFallback(Clamp((float)value / 65535.0f, 0.0f, 1.0f));
  }

  m_isopened = true;
  Log("%s: controller opened", m_name.c_str());
  
  return true;
}

bool CDeviceLtbl::CloseController()
{
  uint8_t prefix[2] = {0x55, 0xAA};
  uint8_t close[2]  = {0x84, 0x00};

  if (!m_isopened)
    return true; //nothing to do here

  m_isopened = false;

  //write the prefix and close command
  if (m_serialport.Write(prefix, 2) == -1 || m_serialport.Write(close, 2) == -1)
  {
    LogError("%s %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }

  Log("%s: controller closed", m_name.c_str());
  
  return true;
}

//wait until the controller has sent 0x55 0xAA
bool CDeviceLtbl::WaitForPrefix()
{
  uint8_t prefix[2] = {0, 0};

  while(1)
  {
    prefix[0] = prefix[1];
    if (m_serialport.Read(prefix + 1, 1, 1000000) == -1)
    {
      LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
      return false;
    }

    if (prefix[0] == 0x55 && prefix[1] == 0xAA)
      return true;
  }
}

