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

#ifndef GRABBER
#define GRABBER

#include <string>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include "config.h"
#include "util/timer.h"

#ifdef HAVE_LIBGL
  #include "vblanksignal.h"
#endif

extern volatile bool xerror;

class CGrabber
{
  public:
    CGrabber(void* boblight, volatile bool& stop, bool sync);
    ~CGrabber();

    std::string& GetError()           { return m_error; }        //retrieves the latest error
    
    void SetInterval(double interval) { m_interval = interval; } //sets interval, negative means vblanks
    void SetSize(int size)            { m_size = size; }         //sets how many pixels we want to grab

    bool Setup();                                                //base setup function
    virtual bool ExtendedSetup();                                //extended stuff for derived classes
    virtual bool Run();                       //main run function

    void SetDebug(const char* display);                          //turn on debug window
    
  protected:

    void              UpdateDimensions();                        //update the size of the root window
    bool              Wait();                                    //wait for the timer or on the vblank
    volatile bool&    m_stop;

    std::string       m_error;                                   //latest error
    
    void*             m_boblight;                                //our handle from libboblight
    
    Display*          m_dpy;                                     //main dpy connection
    Window            m_rootwin;
    XWindowAttributes m_rootattr;
    int               m_size;                                    //nr of pixels on lines to grab

    bool              m_debug;                                   //if we have debug mode on
    Display*          m_debugdpy;                                //dpy connection for debug mode
    Window            m_debugwindow;
    int               m_debugwindowwidth;
    int               m_debugwindowheight;
    GC                m_debuggc;

    void              UpdateDebugFps();                          //the title of the debug window is the fps we capture at
    long double       m_lastupdate;
    long double       m_lastmeasurement;
    long double       m_measurements;
    int               m_nrmeasurements;
    
    double            m_interval;                                //interval in seconds, or negative for vblanks
    CTimer            m_timer;                                   //our timer
    bool              m_sync;                                    //sync mode for libboblight
    
#ifdef HAVE_LIBGL
    CVblankSignal     m_vblanksignal;                            //class that gets vblank signals with glxwaitvideosyncsgi
#endif
};

#endif //GRABBER
