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

#include "signaltimer.h"
#include "lock.h"
#include "misc.h"
#include "timeutils.h"

CSignalTimer::CSignalTimer(volatile bool* stop /*= NULL*/): CTimer(stop)
{
  m_signaled = false;
}

void CSignalTimer::Wait()
{
  CLock lock(m_condition);

  //keep looping until we have a timestamp that's not too old
  int64_t now = GetTimeUs();
  int64_t sleeptime;
  do
  {
    m_time += m_interval;
    sleeptime = m_time - now;
  }
  while(sleeptime <= m_interval * -2LL);
  
  if (sleeptime > m_interval * 2LL) //failsafe, m_time must be bork if we get here
  {
    sleeptime = m_interval * 2LL;
    Reset();
  }

  //wait for the timeout, or for the condition variable to be signaled
  while (!m_signaled && sleeptime > 0LL && !(m_timerstop && *m_timerstop))
  {
    m_condition.Wait(Min(sleeptime, 1000000LL));
    now = GetTimeUs();
    sleeptime = m_time - now;
  }

  //if we get signaled, reset the timestamp, this allows us to be signaled faster than the interval
  if (m_signaled)
  {
    Reset();
    m_signaled = false;
  }
}

void CSignalTimer::Signal()
{
  CLock lock(m_condition);
  m_signaled = true;
  m_condition.Broadcast();
}

