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

#define BOBLIGHT_DLOPEN
#include "lib/boblight.h"

#include <iostream>
#include <signal.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include "util/misc.h"
#include "util/timer.h"
#include "util/daemonize.h"
#include "config.h"
#include "flagmanager-X11.h"

#include "grabber-base.h"
#include "grabber-xgetimage.h"
#include "grabber-xrender.h"

using namespace std;

int  Run();
void SignalHandler(int signum);
int  ErrorHandler(Display* dpy, XErrorEvent* error);

volatile bool stop = false;

CFlagManagerX11 g_flagmanager;

int main (int argc, char *argv[])
{
  //load the boblight lib, if it fails we get a char* from dlerror()
  char* boblight_error = boblight_loadlibrary(NULL);
  if (boblight_error)
  {
    PrintError(boblight_error);
    return 1;
  }

  //try to parse the flags and bitch to stderr if there's an error
  try
  {
    g_flagmanager.ParseFlags(argc, argv);
  }
  catch (string error)
  {
    PrintError(error);
    g_flagmanager.PrintHelpMessage();
    return 1;
  }
  
  if (g_flagmanager.m_printhelp) //print help message
  {
    g_flagmanager.PrintHelpMessage();
    return 1;
  }

  if (g_flagmanager.m_printboblightoptions) //print boblight options (-o [light:]option=value)
  {
    g_flagmanager.PrintBoblightOptions();
    return 1;
  }

  g_flagmanager.SetVideoGamma();

  if (g_flagmanager.m_fork)
    Daemonize();

  if (g_flagmanager.m_pixels == -1) //set default pixels
  {
    if (g_flagmanager.m_method == XGETIMAGE) //xgetimage is crap slow so we grab 16x16 pixels
      g_flagmanager.m_pixels = 16;
    else                                     //xrender is very fast so we scale down the root window
      g_flagmanager.m_pixels = 64;           //to a 64x64 pixels pixmap
  }  
  
  //set up signal handlers
  signal(SIGTERM, SignalHandler);
  signal(SIGINT, SignalHandler);
  XSetErrorHandler(ErrorHandler);

  //keeps running until some unrecoverable error happens
  return Run();
}

int Run()
{
  while(!stop)
  {
    //init boblight
    void* boblight = boblight_init();

    cout << "Connecting to boblightd\n";
    
    //try to connect, if we can't then bitch to stderr and destroy boblight
    if (!boblight_connect(boblight, g_flagmanager.m_address, g_flagmanager.m_port, 5000000) ||
        !boblight_setpriority(boblight, g_flagmanager.m_priority))
    {
      PrintError(boblight_geterror(boblight));
      cout << "Waiting 10 seconds before trying again\n";
      boblight_destroy(boblight);
      sleep(10);
      continue;
    }

    cout << "Connection to boblightd opened\n";
    
    //if we can't parse the boblight option lines (given with -o) properly, just exit
    try
    {
      g_flagmanager.ParseBoblightOptions(boblight);
    }
    catch (string error)
    {
      PrintError(error);
      return 1;
    }

    //set up grabber, based on whether we want to use xrender or xgetimage
    CGrabber* grabber;
    
    if (g_flagmanager.m_method == XGETIMAGE)
      grabber = new CGrabberXGetImage(boblight, stop, g_flagmanager.m_sync);
    else if (g_flagmanager.m_method == XRENDER)
      grabber = new CGrabberXRender(boblight, stop, g_flagmanager.m_sync);

    grabber->SetInterval(g_flagmanager.m_interval);
    grabber->SetSize(g_flagmanager.m_pixels);

    if (g_flagmanager.m_debug)
      grabber->SetDebug(g_flagmanager.m_debugdpy);
    
    if (!grabber->Setup()) //just exit if we can't set up the grabber
    {
      PrintError(grabber->GetError());
      delete grabber;
      boblight_destroy(boblight);
      return 1;
    }

    if (!grabber->Run()) //just exit if some unrecoverable error happens
    {
      PrintError(grabber->GetError());
      delete grabber;
      boblight_destroy(boblight);
      return 1;
    }
    else //boblightd probably timed out, so just try to reconnect
    {
      if (!grabber->GetError().empty())
        PrintError(grabber->GetError());
    }

    delete grabber;

    boblight_destroy(boblight);
  }

  cout << "Exiting\n";
  
  return 0;
}

void SignalHandler(int signum)
{
  if (signum == SIGTERM)
  {
    cout << "caught SIGTERM\n";
    stop = true;
  }
  else if (signum == SIGINT)
  {
    cout << "caught SIGINT\n";
    stop = true;
  }
}

int ErrorHandler(Display* dpy, XErrorEvent* error)
{
  if (error->error_code == BadMatch)
  {
    cout << "caught BadMatch, resolution probably changed\n";
    xerror = true;
  }
  else
  {
    cout << "caught error " << error->error_code << "\n";
    stop = true;
  }
}
