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

#ifndef GRABBERXRENDER
#define GRABBERXRENDER

#include "grabber-base.h"

#include <X11/extensions/Xrender.h>
#include <X11/extensions/XShm.h>
#include <sys/ipc.h>
#include <sys/shm.h>

//class for grabbing with fast xrender
class CGrabberXRender : public CGrabber
{
  public:
    CGrabberXRender(void* boblight, volatile bool& stop, bool sync);
    ~CGrabberXRender();
    
    bool ExtendedSetup();
    bool Run();

  private:

    bool CheckExtensions();
    
    XRenderPictFormat*       m_srcformat;   //not sure what all this is
    XRenderPictFormat*       m_dstformat;
    Picture                  m_srcpicture;
    Picture                  m_dstpicture;
    XRenderPictureAttributes m_pictattr;
    XTransform               m_transform;
    Pixmap                   m_pixmap;      //pixmap we render into
    XShmSegmentInfo          m_shmseginfo;  //we copy the pixmap to an ximage in shared mem
    XImage*                  m_xim;
};

#endif //GRABBERXRENDER
