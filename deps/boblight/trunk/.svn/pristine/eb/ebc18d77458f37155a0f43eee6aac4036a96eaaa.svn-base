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

#include "devicepopen.h"
#include "util/log.h"
#include "util/misc.h"
#include "util/timeutils.h"

#include <iostream>

using namespace std;

CDevicePopen::CDevicePopen (CClientsHandler& clients) : m_timer(&m_stop), CDevice(clients)
{
  m_process = NULL;
}

void CDevicePopen::Sync()
{
  if (m_allowsync)
    m_timer.Signal();
}

bool CDevicePopen::SetupDevice()
{
  m_timer.SetInterval(m_interval);

  //try to open the process
  m_process = popen(m_output.c_str(), "w");
  if (m_process == NULL)
  {
    LogError("%s: popen() %s", m_output.c_str(), GetErrno().c_str());
    return false;
  }

  if (m_delayafteropen > 0)
    USleep(m_delayafteropen, &m_stop);

  return true;
}

bool CDevicePopen::WriteOutput()
{
  //get the channel values from the clienshandler
  int64_t now = GetTimeUs();
  m_clients.FillChannels(m_channels, now, this);

  if (m_debug) //print debug info to stdout when debug is on
    printf("%s:", m_name.c_str());

  //print the values to the process, as float from 0.0 to 1.0
  for (int i = 0; i < m_channels.size(); i++)
  {
    float value = m_channels[i].GetValue(now);
    if (fprintf(m_process, "%f ", value) < 0)
    {
      LogError("%s: fprintf() %s %s", m_name.c_str(), m_output.c_str(), GetErrno().c_str());
      return false;
    }

    if (m_debug)
      printf(" %f", value);
  }

  if (m_debug)
    printf("\n");

  if (fprintf(m_process, "\n") == -1 || fflush(m_process) != 0)
  {
    LogError("%s: fprintf() %s %s", m_name.c_str(), m_output.c_str(), GetErrno().c_str());
    return false;
  }
  
  m_timer.Wait(); //wait for the timer to signal us

  return true;
}

void CDevicePopen::CloseDevice()
{
  if (m_process)
  {
    pclose(m_process);
    m_process = NULL;
  }
}

