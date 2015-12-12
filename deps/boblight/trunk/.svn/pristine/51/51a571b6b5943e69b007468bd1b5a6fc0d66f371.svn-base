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

#include "util/misc.h"
#include <string.h>
#include "vblanksignal.h"

using namespace std;

CVblankSignal::CVblankSignal()
{
  m_dpy = NULL;
  m_vinfo = NULL;
  m_window = (Window)0;
  m_context = NULL;
}

CVblankSignal::~CVblankSignal()
{
  Close();
}

//set up a fake window with a glx context so we can wait for a vblank
bool CVblankSignal::Setup()
{
  int singlebufferattributes[] = {
    GLX_RGBA,
    GLX_RED_SIZE,      0,
    GLX_GREEN_SIZE,    0,
    GLX_BLUE_SIZE,     0,
    None
  };

  int                  returnv;
  int                  swamask;
  unsigned int         vblankcount;
  XSetWindowAttributes swa;

  m_dpy = NULL;
  m_vinfo = NULL;
  m_context = NULL;
  m_window = (Window)0;

  m_dpy = XOpenDisplay(NULL);
  if (!m_dpy)
  {
    
    m_error = "Unable to open display";
    return false;
  }

  if (!glXQueryExtension(m_dpy, NULL, NULL))
  {
    m_error = "X server does not support GLX";
    return false;
  }

  if (!strstr(glXQueryExtensionsString(m_dpy, DefaultScreen(m_dpy)), "SGI_video_sync"))
  {
    m_error = "X server does not support SGI_video_sync";
    return false;
  }

  m_vinfo = glXChooseVisual(m_dpy, DefaultScreen(m_dpy), singlebufferattributes);
  if (!m_vinfo)
  {
    m_error = "glXChooseVisual returned NULL";
    return false;
  }

  swa.border_pixel = 0;
  swa.event_mask = StructureNotifyMask;
  swa.colormap = XCreateColormap(m_dpy, RootWindow(m_dpy, m_vinfo->screen), m_vinfo->visual, AllocNone );
  swamask = CWBorderPixel | CWColormap | CWEventMask;

  m_window = XCreateWindow(m_dpy, RootWindow(m_dpy, m_vinfo->screen), 0, 0, 256, 256, 0,
                           m_vinfo->depth, InputOutput, m_vinfo->visual, swamask, &swa);

  m_context = glXCreateContext(m_dpy, m_vinfo, NULL, True);
  if (!m_context)
  {
    m_error = "glXCreateContext returned NULL";
    return false;
  }

  returnv = glXMakeCurrent(m_dpy, m_window, m_context);
  if (returnv != True)
  {
    m_error = "glXMakeCurrent returned " + ToString(returnv);
    return false;
  }

  m_glXWaitVideoSyncSGI = (int (*)(int, int, unsigned int*))glXGetProcAddress((const GLubyte*)"glXWaitVideoSyncSGI");
  if (!m_glXWaitVideoSyncSGI)
  {
    m_error = "glXWaitVideoSyncSGI not found";
    return false;
  }

  returnv = m_glXWaitVideoSyncSGI(2, 0, &vblankcount);
  if (returnv)
  {
    m_error = "glXWaitVideoSyncSGI returned %i" + ToString(returnv);
    return false;
  }

  m_glXGetVideoSyncSGI = (int (*)(unsigned int*))glXGetProcAddress((const GLubyte*)"glXGetVideoSyncSGI");
  if (!m_glXGetVideoSyncSGI)
  {
    m_error = "glXGetVideoSyncSGI not found";
    return false;
  }

  returnv = m_glXGetVideoSyncSGI(&vblankcount);
  if (returnv)
  {
    m_error = "glXGetVideoSyncSGI returned " + ToString(returnv);
    return false;
  }

  m_prevvblank = vblankcount;
  m_vblankclock = vblankcount;
  m_isreset = false;
  
  return true;
}

void CVblankSignal::Close()
{
  if (m_vinfo)
  {
    XFree(m_vinfo);
    m_vinfo = NULL;
  }
  if (m_context)
  {
    glXDestroyContext(m_dpy, m_context);
    m_context = NULL;
  }
  if (m_window)
  {
    XDestroyWindow(m_dpy, m_window);
    m_window = (Window)0;
  }
  if (m_dpy)
  {
    XCloseDisplay(m_dpy);
    m_dpy = NULL;
  }

  m_glXGetVideoSyncSGI = NULL;
  m_glXWaitVideoSyncSGI = NULL;
}

bool CVblankSignal::Wait(unsigned int nrvblanks /*= 1*/)
{
  int          returnv;
  unsigned int vblankcount;

  //get the current value of the vblank counter
  returnv = m_glXGetVideoSyncSGI(&vblankcount);
  if (returnv)
  {
    m_error = "glXGetVideoSyncSGI returned " + ToString(returnv);
    return false;
  }

  //wait until we hit the requested vblank timestamp
  m_vblankclock += nrvblanks;
  int diff = (int)m_vblankclock - (int)vblankcount;
  if (diff > 0)
  {
    returnv = m_glXWaitVideoSyncSGI(diff + 1, m_vblankclock % (diff + 1), &vblankcount);
    if (returnv)
    {
      m_error = "glXGetVideoSyncSGI returned " + ToString(returnv);
      return false;
    }
  }

  //if the vblank counter updated we're good
  if (vblankcount > m_prevvblank)
  {
    m_isreset = false;
    m_prevvblank = vblankcount;
  }
  else if (!m_isreset) //if it didn't update, we try to detach and attach the glx context
  {                    //because on some videodrivers (nvidia) glXWaitVideoSyncSGI breaks when the displaymode changes
    returnv = glXMakeCurrent(m_dpy, None, NULL);
    if (returnv != True)
    {
      m_error = "glXMakeCurrent returned " + ToString(returnv);
      return false;
    }
    returnv = glXMakeCurrent(m_dpy, m_window, m_context);
    if (returnv != True)
    {
      m_error = "glXMakeCurrent returned " + ToString(returnv);
      return false;
    }

    m_isreset = true;
  }
  else //if the reattachment didn't work, set up glx again
  {
    Close();
    return Setup();
  }
  
  return true;
}
  
