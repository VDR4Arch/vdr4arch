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

#define BOBLIGHT_DLOPEN
#include "lib/boblight.h"

#include <iostream>
#include <string>
#include <vector>
#include <signal.h>
#include <unistd.h>

#include "config.h"
#include "util/misc.h"
#include "util/daemonize.h"
#include "flagmanager-constant.h"

using namespace std;

int  Run();
void SignalHandler(int signum);

volatile bool stop = false;

CFlagManagerConstant g_flagmanager;

int main(int argc, char *argv[])
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

  if (g_flagmanager.m_fork)
    Daemonize();

  //set up signal handlers
  signal(SIGTERM, SignalHandler);
  signal(SIGINT, SignalHandler);

  //keep running until we want to quit
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

    //try to parse the boblight flags and bitch to stderr if we can't
    try
    {
      g_flagmanager.ParseBoblightOptions(boblight);
    }
    catch (string error)
    {
      PrintError(error);
      return 1;
    }

    //load the color into int array
    int rgb[3] = {(g_flagmanager.m_color >> 16) & 0xFF, (g_flagmanager.m_color >> 8) & 0xFF, g_flagmanager.m_color & 0xFF};
   
    //set all lights to the color we want and send it
    boblight_addpixel(boblight, -1, rgb);
    if (!boblight_sendrgb(boblight, 1, NULL)) //some error happened, probably connection broken, so bitch and try again
    {
      PrintError(boblight_geterror(boblight));
      boblight_destroy(boblight);
      continue;
    }

    //keep checking the connection to boblightd every 10 seconds, if it breaks we try to connect again
    while(!stop)
    {
      if (!boblight_ping(boblight, NULL))
      {
        PrintError(boblight_geterror(boblight));
        break;
      }
      sleep(10);
    }

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
