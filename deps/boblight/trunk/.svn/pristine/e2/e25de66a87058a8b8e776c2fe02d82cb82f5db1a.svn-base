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

#include <time.h>
#include <assert.h>
#include "mutex.h"

CMutex::CMutex()
{
  //make a recursive mutex
  pthread_mutexattr_t attr;
  pthread_mutexattr_init(&attr);
  pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);

  pthread_mutex_init(&m_mutex, &attr);

  pthread_mutexattr_destroy(&attr);

  m_refcount = 0;
}

CMutex::~CMutex()
{
  pthread_mutex_destroy(&m_mutex);
}

void CMutex::Unlock()
{
  m_refcount--;
  assert(m_refcount >= 0);
  pthread_mutex_unlock(&m_mutex);
}

bool CMutex::TryLock()
{
  if (pthread_mutex_trylock(&m_mutex) == 0)
  {
    m_refcount++;
    assert(m_refcount > 0);
    return true;
  }
  else
  {
    return false;
  }
}

bool CMutex::Lock()
{
  pthread_mutex_lock(&m_mutex);
  m_refcount++;
  assert(m_refcount > 0);
  return true;
}

