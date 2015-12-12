/*
* deviceola.cpp
  Copyright (C) Hippy 2010
  
* Use OLA (and all it's dmx/ethernet output devices) with boblightd
* Find ola and instructions at http://www.opendmx.net/index.php/Open_Lighting_Architecture
*/


/*

# example device section for boblight.conf
[device]
name device1
type ola
# OLA universe to send to
output 1
# sending 512 channels.
channels 512
interval 20000

*/


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

/* now... on with the goodness */


#include <ola/DmxBuffer.h>
#include <ola/Logging.h>
#include <ola/OlaClientWrapper.h>
#include <ola/io/SelectServer.h>

#include "deviceola.h"
#include "util/log.h"
#include "util/misc.h"
#include "util/timeutils.h"

#include <iostream>
#include <cstdlib>

using namespace std;


CDeviceOla::CDeviceOla (CClientsHandler& clients) : m_timer(&m_stop), CDevice(clients)
{
  m_outbuffer.Blackout();  // clear the ola buffer
}


void CDeviceOla::Sync()
{
  m_timer.Signal();
}


bool CDeviceOla::SetupDevice()
{
  char * pEnd;

  m_timer.SetInterval(m_interval);

  ola::InitLogging(ola::OLA_LOG_WARN, ola::OLA_LOG_STDERR); // switch on ola logging

  if (!m_client.Setup())
  {
    LogError("%s: failed to setup ola client! Is olad running?", m_name.c_str());
    return false;  // failed to connect
  }

  m_universe = strtol(m_output.c_str(),&pEnd,10); // set universe number from output string

  return true;  // ready to roll
}



bool CDeviceOla::WriteOutput()
{
  int64_t now = GetTimeUs(); // tick tick tick

  m_clients.FillChannels(m_channels, now, this); // get the channel values from the clients handler

  for (int ch = 0; ch < m_channels.size(); ch++)
  {
    m_outbuffer.SetChannel(ch, F2B(m_channels[ch].GetValue(now)));  // set the channel to the output
  }

  if (m_client.SendDmx(m_universe, m_outbuffer) == false)
  {  // Send the buffer
    LogError("%s: failed to SendDmx to universe %i", m_name.c_str(), m_universe);
    return false; // failed!
  }

  m_timer.Wait(); // timer signal

  return true;
}


void CDeviceOla::CloseDevice()
{
  m_client.Stop();
}
