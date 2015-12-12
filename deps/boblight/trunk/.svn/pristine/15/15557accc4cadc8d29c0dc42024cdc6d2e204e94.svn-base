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

#ifndef CVBLANKSIGNAL
#define CVBLANKSIGNAL

#include <string>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <GL/glx.h>

//class for waiting on vertical blanks with glxwaitvideosyncsgi
class CVblankSignal
{
  public:
    CVblankSignal();
    ~CVblankSignal();

    bool Setup();
    void Close();
    bool Wait(unsigned int nrvblanks = 1);

    std::string& GetError() { return m_error; }

  private:
    //function pointers, because SGI_video_sync is an extension
    int  (*m_glXWaitVideoSyncSGI)(int, int, unsigned int*);
    int  (*m_glXGetVideoSyncSGI)(unsigned int*);

    std::string  m_error;      //last error
    
    Display*     m_dpy;        //our dpy connection
    XVisualInfo* m_vinfo;
    Window       m_window;
    GLXContext   m_context;

    unsigned int m_prevvblank; //previous value of the vblank counter
    unsigned int m_vblankclock;//vblank value we need to wait for
    bool         m_isreset;    //glxwaitvideosyncsgi can break, try to reset once
};

#endif //CVBLANKSIGNAL
