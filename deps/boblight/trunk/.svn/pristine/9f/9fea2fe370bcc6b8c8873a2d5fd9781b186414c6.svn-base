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

#include "devicedioder.h"
#include "util/log.h"
#include "util/misc.h"
#include "util/timeutils.h"

// support from device from: http://cauldrondevelopment.com/blog/2009/12/29/a-real-ikea-dioder-hack/

/*
protocol:

commands are sent as single bytes

Device has 7 commands:

'0' : disable pic
'1' : enable pic
'o' : all lights off
'r' : toggle red
'g' : toggle green
'b' : toggle blue
0xFF: set color

How set color works:

Device needs 0xFF to go into set color mode, then needs 'r', 'g' or 'b' to select the color, then one byte to set the value of this color.
Examples:

0xFF 'r' 255
0xFF 'g' 128
0xFF 'b' 64

*/

CDeviceDioder::CDeviceDioder(CClientsHandler& clients) : CDeviceRS232(clients)
{
  m_buff = NULL;
}

bool CDeviceDioder::SetupDevice()
{
  m_timer.SetInterval(m_interval);

  if (!OpenSerialPort())
    return false;

  m_serialport.PrintToStdOut(m_debug); //print serial data to stdout when debug mode is on

  if (m_delayafteropen > 0)
    USleep(m_delayafteropen, &m_stop);

  //make sure we're controlling it
  uint8_t open = '0';
  if (m_serialport.Write(&open, 1) == -1)
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }

  m_buff = new uint8_t[m_channels.size() * 3];

  return true;
}

bool CDeviceDioder::WriteOutput()
{
  //get the channel values from the clienshandler
  int64_t now = GetTimeUs();
  m_clients.FillChannels(m_channels, now, this);

  char colors[3] = {'r', 'g', 'b'};
  int  color = 0;

  //put channel values in the output buffer
  for (int i = 0; i < m_channels.size(); i++)
  {
    int value = Clamp(Round32(m_channels[i].GetValue(now) * 255.0f), 0, 255);

    m_buff[i * 3 + 0] = 0xFF;
    m_buff[i * 3 + 1] = colors[color];
    m_buff[i * 3 + 2] = value;

    color = (color + 1) % 3;
  }

  //write output to the serial port
  if (m_serialport.Write(m_buff, m_channels.size() * 3) == -1)
  {
    LogError("%s: %s", m_name.c_str(), m_serialport.GetError().c_str());
    return false;
  }
    
  m_timer.Wait(); //wait for the timer to signal us

  return true;
}

void CDeviceDioder::CloseDevice()
{
  if (m_buff)
  {
    delete m_buff;
    m_buff = NULL;
  }

  //turn off all lights
  uint8_t off = 'o';
  m_serialport.Write(&off, 1);

  m_serialport.Close();
}

