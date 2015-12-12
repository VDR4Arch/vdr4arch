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

#include <iostream>
#include <string>
#include <signal.h>
#include <unistd.h>

#include "util/log.h"
#include "util/tcpsocket.h"
#include "util/messagequeue.h"
#include "util/daemonize.h"
#include "client.h"
#include "configuration.h"
#include "device/device.h"
#include "config.h"

#define DEFAULTCONF "/etc/boblight.conf"

using namespace std;

volatile bool g_stop = false;

void PrintFlags(int argc, char *argv[]);
void SignalHandler(int signum);
void PrintHelpMessage();
bool ParseFlags(int argc, char *argv[], bool& help, string& configfile, bool& fork);

int main (int argc, char *argv[])
{
  //read flags
  string configfile;
  bool   help;
  bool   bfork;

  if (!ParseFlags(argc, argv, help, configfile, bfork) || help)
  {
    PrintHelpMessage();
    return 1;
  }

  if (bfork)
  {
    Daemonize();
    logtostderr = false;
  }
  
  //init our logfile
  SetLogFile("boblightd.log");
  PrintFlags(argc, argv);

  //set up signal handlers
  signal(SIGTERM, SignalHandler);
  signal(SIGINT, SignalHandler);

  vector<CDevice*> devices; //where we store devices
  vector<CLight>   lights;  //lights pool
  CClientsHandler  clients(lights);

  { //save some ram by removing CConfig from the stack when it's not needed anymore
    CConfig config;  //class for loading and parsing config
    //load and parse config
    if (!config.LoadConfigFromFile(configfile))
      return 1;
    if (!config.CheckConfig())
      return 1;
    if (!config.BuildConfig(clients, devices, lights))
      return 1;
  }

  //start the devices
  Log("starting devices");
  for (int i = 0; i < devices.size(); i++)
    devices[i]->StartThread();

  //run the clients handler
  while(!g_stop)
    clients.Process();

  //signal that the devices should stop
  Log("signaling devices to stop");
  for (int i = 0; i < devices.size(); i++)
    devices[i]->AsyncStopThread();

  //clean up the clients handler
  clients.Cleanup();

  //stop the devices
  Log("waiting for devices to stop");
  for (int i = 0; i < devices.size(); i++)
    devices[i]->StopThread();

  Log("exiting");
  
  return 0;
}

void PrintFlags(int argc, char *argv[])
{
  string flags = "starting";
  
  for (int i = 0; i < argc; i++)
  {
    flags += " ";
    flags += argv[i];
  }

  Log("%s", flags.c_str());
}

void SignalHandler(int signum)
{
  if (signum == SIGTERM)
  {
    Log("caught SIGTERM");
    g_stop = true;
  }
  else if (signum == SIGINT)
  {
    Log("caught SIGINT");
    g_stop = true;
  }
  else
  {
    Log("caught %i", signum);
  }
}

void PrintHelpMessage()
{
  cout << "Usage: boblightd [OPTION]\n";
  cout << "\n";
  cout << "  options:\n";
  cout << "\n";
  cout << "  -c  set the config file, default is " << DEFAULTCONF << "\n";
  cout << "  -f  fork\n";
  cout << "\n";
}

bool ParseFlags(int argc, char *argv[], bool& help, string& configfile, bool& fork)
{
  help = false;
  fork = false;
  configfile = DEFAULTCONF;

  opterr = 0; //no getopt errors to stdout, we bitch ourselves
  int c;

  while ((c = getopt (argc, argv, "c:hf")) != -1)
  {
    if (c == 'c')
    {
      configfile = optarg;
    }
    else if (c == 'h')
    {
      help = true;
      return true;
    }
    else if (c == 'f')
    {
      fork = true;
    }
    else if (c == '?')
    {
      if (optopt == 'c')
      {
        PrintError("Option " + ToString((char)optopt) + " requires an argument");
      }
      else
      {
        PrintError("Unknown option " + ToString((char)optopt));
      }
      return false;
    }
  }

  return true;
}
