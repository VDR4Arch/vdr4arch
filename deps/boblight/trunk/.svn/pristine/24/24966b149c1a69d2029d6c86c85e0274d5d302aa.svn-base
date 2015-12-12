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

#include <string.h>

#include "util/log.h"
#include "util/misc.h"
#include "devicers232.h"
#include "util/timeutils.h"

CDeviceRS232::CDeviceRS232(CClientsHandler& clients) : m_timer(&m_stop), CDevice(clients)
{
  m_type = -1;
  m_buff = NULL;
  m_max = 255;
  m_buffsize = 0;
}

void CDeviceRS232::SetType(int type)
{
  m_type = type;
  if (type == ATMO) //atmo devices have two bytes for startchannel and one byte for number of channels
  {
    //it doesn't say anywhere if the startchannel is big endian or little endian, so I'm just starting at 0
    m_prefix.push_back(0xFF);
    m_prefix.push_back(0);
    m_prefix.push_back(0);
    m_prefix.push_back(m_channels.size());
  }
  else if (type == KARATE)
  {
    m_prefix.push_back(0xAA);
    m_prefix.push_back(0x12);
    m_prefix.push_back(0);
    m_prefix.push_back(m_channels.size());
  }
  else if (type == SEDU)
  {
    m_prefix.push_back(0xA5);
    m_prefix.push_back(0x5A);
    m_postfix.push_back(0xA1);
  }
}

void CDeviceRS232::Sync()
{
  if (m_allowsync)
    m_timer.Signal();
}

bool CDeviceRS232::SetupDevice()
{
  m_timer.SetInterval(m_interval);

  if (!OpenSerialPort())
    return false;

  if (m_delayafteropen > 0)
    USleep(m_delayafteropen, &m_stop);

  //bytes per channel
  m_bytes = 1;
  while (Round64(pow(256, m_bytes)) <= m_max)
    m_bytes++;

  //allocate a buffer, that can hold the prefix,the number of bytes per channel and the postfix
  m_buffsize = m_prefix.size() + m_channels.size() * m_bytes + m_postfix.size();
  m_buff = new uint8_t[m_buffsize];

  //copy in the prefix
  if (m_prefix.size() > 0)
    memcpy(m_buff, &m_prefix[0], m_prefix.size());

  //copy in the postfix
  if (m_postfix.size() > 0)
    memcpy(m_buff + m_prefix.size() + m_channels.size() * m_bytes, &m_postfix[0], m_postfix.size());

  //set channel bytes to 0, write it twice to make sure the controller is in sync
  memset(m_buff + m_prefix.size(), 0, m_channels.size() * m_bytes);
  for (int i = 0; i < 2; i++)
  {
    if (m_serialport.Write(m_buff, m_buffsize) == -1)
    {
      LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
      return false;
    }
  }

  return true;
}

bool CDeviceRS232::WriteOutput()
{
  //get the channel values from the clientshandler
  int64_t now = GetTimeUs();
  m_clients.FillChannels(m_channels, now, this);

  //put the values in the buffer, big endian
  for (int i = 0; i < m_channels.size(); i++)
  {
    int64_t output = Round64((double)m_channels[i].GetValue(now) * m_max);
    output = Clamp(output, 0, m_max);

    for (int j = 0; j < m_bytes; j++)
      m_buff[m_prefix.size() + i * m_bytes + j] = (output >> ((m_bytes - j - 1) * 8)) & 0xFF;
  }

  //calculate checksum
  if (m_type == KARATE)
  {
    m_buff[2] = m_buff[0] ^ m_buff[1];
    for (int i = 3; i < m_buffsize; i++)
      m_buff[2] ^= m_buff[i];
  }

  //write the channel values out the serial port
  if (m_serialport.Write(m_buff, m_buffsize) == -1)
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }

  m_timer.Wait();
  
  return true;
}

void CDeviceRS232::CloseDevice()
{
  //if opened, set all channels to 0 before closing
  if (m_buff)
  {
    memset(m_buff + m_prefix.size(), 0, m_channels.size() * m_bytes);
    m_serialport.Write(m_buff, m_buffsize);

    delete m_buff;
    m_buff = NULL;
    m_buffsize = 0;
  }

  m_serialport.Close();
}

bool CDeviceRS232::OpenSerialPort()
{
  bool opened = m_serialport.Open(m_output, m_rate);
  if (m_serialport.HasError())
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    if (opened)
      Log("%s: %s had a non fatal error, it might still work, continuing", m_name.c_str(), m_output.c_str());
  }

  m_serialport.PrintToStdOut(m_debug); //print serial data to stdout when debug mode is on

  return opened;
}

