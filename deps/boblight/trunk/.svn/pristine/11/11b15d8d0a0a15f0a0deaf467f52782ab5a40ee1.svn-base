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

#include <iostream>
#include <signal.h>
#include <unistd.h>

#define BOBLIGHT_DLOPEN
#include "lib/boblight.h"
#include "util/misc.h"
#include "util/daemonize.h"
#include "flagmanager-v4l.h"
#include "videograbber.h"

CFlagManagerV4l g_flagmanager;

using namespace std;

void SignalHandler(int signum);
int Run();

volatile bool stop = false;

int main(int argc, char *argv[])
{
  //load the boblight lib, if it fails we get a char* from dlerror()
  char* boblight_error = boblight_loadlibrary(NULL);
  if (boblight_error)
  {
    PrintError(boblight_error);
    return 1;
  }

  int returnv;

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

  //set up signal handlers
  signal(SIGTERM, SignalHandler);
  signal(SIGINT, SignalHandler);

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
    if (!boblight_connect(boblight, g_flagmanager.m_address, g_flagmanager.m_port, 5000000))
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

    //set up videograbber
    CVideoGrabber videograbber;
    try
    {
      videograbber.Setup();
    }
    catch(string error)
    {
      PrintError(error);
      boblight_destroy(boblight);
      return 1;
    }

    try
    {
      videograbber.Run(stop, boblight);  //this will keep looping until we should stop or boblight gives an error
    }
    catch (string error)
    {
      PrintError(error);
      boblight_destroy(boblight);
      return 1;
    }

    if (!videograbber.GetError().empty())
      PrintError(videograbber.GetError());
    
    videograbber.Cleanup();

    boblight_destroy(boblight);
  }

  cout << "Exiting\n";
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

