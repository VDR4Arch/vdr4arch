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

#include "grabber-xrender.h"

#include <string.h>

#include "util/misc.h"

#define BOBLIGHT_DLOPEN_EXTERN
#include "lib/boblight.h"

using namespace std;

CGrabberXRender::CGrabberXRender(void* boblight, volatile bool& stop, bool sync) : CGrabber(boblight, stop, sync)
{
  m_srcformat = NULL;
  m_dstformat = NULL;
  m_pixmap = NULL;
  m_srcpicture = None;
  m_dstpicture = None;

  memset(&m_pictattr, 0, sizeof(m_pictattr));
  m_pictattr.repeat = RepeatNone;

  m_transform.matrix[0][0] = 0;
  m_transform.matrix[0][1] = 0;
  m_transform.matrix[0][2] = 0;
  m_transform.matrix[1][0] = 0;
  m_transform.matrix[1][1] = 0;
  m_transform.matrix[1][2] = 0;
  m_transform.matrix[2][0] = 0;
  m_transform.matrix[2][1] = 0;
  m_transform.matrix[2][2] = 0;
}

CGrabberXRender::~CGrabberXRender()
{
  XRenderFreePicture(m_dpy, m_srcpicture);
  XRenderFreePicture(m_dpy, m_dstpicture);

  XFreePixmap(m_dpy, m_pixmap);

  XShmDetach(m_dpy, &m_shmseginfo);
  XDestroyImage(m_xim);
  shmdt(m_shmseginfo.shmaddr);
  shmctl(m_shmseginfo.shmid, IPC_RMID, NULL);
}

bool CGrabberXRender::ExtendedSetup()
{
  if (!CheckExtensions())
    return false;

  m_pixmap = XCreatePixmap(m_dpy, m_rootwin, m_size, m_size, m_rootattr.depth);

  m_srcformat = XRenderFindVisualFormat(m_dpy, m_rootattr.visual);
  m_dstformat = XRenderFindVisualFormat(m_dpy, m_rootattr.visual); //how the hell do I get a visual from a pixmap?

  m_srcpicture = XRenderCreatePicture(m_dpy, m_rootwin, m_srcformat, CPRepeat, &m_pictattr);
  m_dstpicture = XRenderCreatePicture(m_dpy, m_pixmap,  m_dstformat, CPRepeat, &m_pictattr);

  //we want bilinear scaling
  XRenderSetPictureFilter(m_dpy, m_srcpicture, "bilinear", NULL, 0);

  //set up shared memory ximage
  m_xim = XShmCreateImage(m_dpy, m_rootattr.visual, m_rootattr.depth, ZPixmap, NULL, &m_shmseginfo, m_size, m_size);
  m_shmseginfo.shmid = shmget(IPC_PRIVATE, m_xim->bytes_per_line * m_xim->height, IPC_CREAT | 0777);
  m_shmseginfo.shmaddr = reinterpret_cast<char*>(shmat(m_shmseginfo.shmid, NULL, 0));
  m_xim->data = m_shmseginfo.shmaddr;
  m_shmseginfo.readOnly = False;
  XShmAttach(m_dpy, &m_shmseginfo);
  
  return true;
}

bool CGrabberXRender::CheckExtensions()
{
  int eventbase;
  int errorbase;
  int majorver;
  int minorver;

  if (!XRenderQueryExtension(m_dpy, &eventbase, &errorbase))
  {
    m_error = "XRender extension not found";
    return false;
  }
  if (!XRenderQueryVersion(m_dpy, &majorver, &minorver))
  {
    m_error = "Unable to get XRender version";
    return false;
  }
  if (majorver != 0 || minorver < 10)
  {
    m_error = "Incompatible XRender extension"; //TODO: verify this
    return false;
  }

  if (!XShmQueryExtension(m_dpy))
  {
    m_error = "Shared memory extension not supported";
    return false;
  }
  
  return true;
}

bool CGrabberXRender::Run()
{
  XImage* xim;
  unsigned long pixel;
  int rgb[3];

  boblight_setscanrange(m_boblight, m_size, m_size);

  while(!m_stop)
  {
    UpdateDimensions();

    //we want to scale the root window to the pixmap
    m_transform.matrix[0][0] = m_rootattr.width;
    m_transform.matrix[1][1] = m_rootattr.height;
    m_transform.matrix[2][2] = m_size;
    
    XRenderSetPictureTransform (m_dpy, m_srcpicture, &m_transform);

    //render the thing
    XRenderComposite(m_dpy, PictOpSrc, m_srcpicture, None, m_dstpicture, 0, 0, 0, 0, 0, 0, m_size, m_size);
    XSync(m_dpy, False);

    //copy pixmap to the ximage in shared mem
    XShmGetImage(m_dpy, m_pixmap, m_xim, 0, 0, AllPlanes);

    //read out the pixels
    for (int y = 0; y < m_size && !m_stop; y++)
    {
      for (int x = 0; x < m_size && !m_stop; x++)
      {
        pixel = XGetPixel(m_xim, x, y);
        
        rgb[0] = (pixel >> 16) & 0xff;
        rgb[1] = (pixel >>  8) & 0xff;
        rgb[2] = (pixel >>  0) & 0xff;

        boblight_addpixelxy(m_boblight, x, y, rgb);
      }
    }

    //send pixeldata to boblight
    if (!boblight_sendrgb(m_boblight, m_sync, NULL))
    {
      m_error = boblight_geterror(m_boblight);
      return true; //recoverable error
    }

    //when in debug mode, put the captured image on the debug window
    if (m_debug)
    {
      int x = (m_debugwindowwidth - m_size) / 2;
      int y = (m_debugwindowheight - m_size) / 2;
      XPutImage(m_debugdpy, m_debugwindow, m_debuggc, m_xim, 0, 0, x, y, m_size, m_size);
      XSync(m_debugdpy, False);
    }

    if (!Wait())
    {
#ifdef HAVE_LIBGL
      m_error = m_vblanksignal.GetError();
#endif
      return false; //unrecoverable error
    }

    UpdateDebugFps();
  }

  m_error.clear();
  
  return true;
}
