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

#include "util/inclstdint.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <X11/Xatom.h>

#include "util/misc.h"
#include "grabber-base.h"
#include "util/timeutils.h"

using namespace std;

volatile bool xerror = false;

CGrabber::CGrabber(void* boblight, volatile bool& stop, bool sync) : m_stop(stop), m_timer(&stop)
{
  m_boblight = boblight;
  m_dpy = NULL;
  m_debug = false;
  m_sync = sync;
}

CGrabber::~CGrabber()
{
  if (m_dpy) //close display connection if opened
  {
    XCloseDisplay(m_dpy);
    m_dpy = NULL;
  }

  if (m_debug) //close debug dpy connection if opened
  {
    XFreeGC(m_debugdpy, m_debuggc);
    XDestroyWindow(m_debugdpy, m_debugwindow);
    XCloseDisplay(m_debugdpy);
    m_debug = false;
  }
}

bool CGrabber::Setup()
{
  m_dpy = XOpenDisplay(NULL);  //try to open a dpy connection
  if (m_dpy == NULL)
  {
    m_error = "unable to open display";
    if (getenv("DISPLAY"))
      m_error += " " + string(getenv("DISPLAY"));
    else
      m_error += ", DISPLAY environment variable not set";

    return false; //unrecoverable error
  }

  m_rootwin = RootWindow(m_dpy, DefaultScreen(m_dpy));
  UpdateDimensions();

  if (m_interval > 0.0) //set up timer
  {
    m_timer.SetInterval(Round64(m_interval * 1000000.0));
  }
#ifdef HAVE_LIBGL
  else //interval is negative so sync to vblank instead
  {
    if (!m_vblanksignal.Setup())
    {
      m_error = m_vblanksignal.GetError();
      return false; //unrecoverable error
    }
  }
#endif

  m_error.clear();

  return ExtendedSetup(); //run stuff from derived classes
}

bool CGrabber::ExtendedSetup()
{
  return true;
}

void CGrabber::UpdateDimensions() //update size of root window
{
  XGetWindowAttributes(m_dpy, m_rootwin, &m_rootattr);
}

bool CGrabber::Run()
{
  return false;
}

bool CGrabber::Wait()
{
  if (m_interval > 0.0) //wait for timer
  {
    m_timer.Wait();
  }
#ifdef HAVE_LIBGL
  else //interval is negative, wait for vblanks
  {
    if (!m_vblanksignal.Wait(Round32(m_interval * -1.0)))
    {
      m_error = m_vblanksignal.GetError();
      return false; //unrecoverable error
    }
  }
#endif

  return true;
}

void CGrabber::SetDebug(const char* display)
{
  //set up a display connection, a window and a gc so we can show what we're capturing
  
  m_debugdpy = XOpenDisplay(display);
  assert(m_debugdpy);
  m_debugwindowwidth = Max(200, m_size);
  m_debugwindowheight = Max(200, m_size);
  m_debugwindow = XCreateSimpleWindow(m_debugdpy, RootWindow(m_debugdpy, DefaultScreen(m_debugdpy)),
                                      0, 0, m_debugwindowwidth, m_debugwindowheight, 0, 0, 0);
  XMapWindow(m_debugdpy, m_debugwindow);
  XSync(m_debugdpy, False);

  m_debuggc = XCreateGC(m_debugdpy, m_debugwindow, 0, NULL);

  //set up stuff for measuring fps
  m_lastupdate = GetTimeSec<long double>();
  m_lastmeasurement = m_lastupdate;
  m_measurements = 0.0;
  m_nrmeasurements = 0.0;
  
  m_debug = true;
}

void CGrabber::UpdateDebugFps()
{
  if (m_debug)
  {
    long double now = GetTimeSec<long double>(); //current timestamp
    m_measurements += now - m_lastmeasurement;              //diff between last time we were here
    m_nrmeasurements++;                                     //got another measurement
    m_lastmeasurement = now;                                //save the timestamp

    if (now - m_lastupdate >= 1.0)                          //if we've measured for one second, place fps on debug window title
    {
      m_lastupdate = now;

      long double fps = 0.0;
      if (m_nrmeasurements > 0) fps = 1.0 / (m_measurements / m_nrmeasurements); //we need at least one measurement
      m_measurements = 0.0;
      m_nrmeasurements = 0;

      string strfps = ToString(fps) + " fps";

      XTextProperty property;
      property.value = reinterpret_cast<unsigned char*>(const_cast<char*>(strfps.c_str()));
      property.encoding = XA_STRING;
      property.format = 8;
      property.nitems = strfps.length();

      XSetWMName(m_debugdpy, m_debugwindow, &property);
    }
  }
}
