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

#include "thread.h"

CThread::CThread()
{
  m_thread = NULL;
  m_running = false;
}

CThread::~CThread()
{
  StopThread();
}

void CThread::StartThread()
{
  m_stop = false;
  m_running = true;
  pthread_create(&m_thread, NULL, ThreadFunction, reinterpret_cast<void*>(this));
}

void* CThread::ThreadFunction(void* args)
{
  CThread* thread = reinterpret_cast<CThread*>(args);
  thread->Process();
  thread->m_running = false;
}

void CThread::Process()
{
}

void CThread::StopThread()
{
  AsyncStopThread();
  JoinThread();
}

void CThread::AsyncStopThread()
{
  m_stop = true;
}

void CThread::JoinThread()
{
  if (m_thread)
  {
    pthread_join(m_thread, NULL);
    m_thread = NULL;
  }
}

bool CThread::IsRunning()
{
  return m_running;
}

