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

#include <cstdarg>
#include <cstdio>
#include <fstream>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <sys/stat.h>
#include <time.h>
#include <sstream>
#include <vector>
#include <sys/time.h>

#include "log.h"
#include "mutex.h"
#include "lock.h"
#include "misc.h"

using namespace std;

bool logtostderr = true;
bool printlogtofile = true;

static CMutex   g_logmutex;
static ofstream g_logfile;

//returns hour:minutes:seconds:microseconds
string GetStrTime()
{
  struct timeval tv;
  struct tm      time;
  time_t         now;

  //get current time
  gettimeofday(&tv, NULL);
  now = tv.tv_sec; //seconds since EPOCH
  localtime_r(&now, &time); //convert to hours, minutes, seconds

  char buff[100];
  sprintf(buff, "%02i:%02i:%02i.%06i", time.tm_hour, time.tm_min, time.tm_sec, (int)tv.tv_usec);

  return buff;
}

bool InitLog(string filename, ofstream& logfile)
{
  if (!getenv("HOME"))
  {
    PrintError("$HOME is not set");
    return false;
  }
  
  string directory = static_cast<string>(getenv("HOME")) + "/.boblight/";
  string fullpath = directory + filename;

  //try to make the directory the log goes in
  if (mkdir(directory.c_str(), S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH) == -1)
  {
    //if it already exists we're ok
    if (errno != EEXIST)
    {
      PrintError("unable to make directory " + directory + ":\n" + GetErrno());
      return false;
    }
  }

  //we keep around 5 old logfiles
  for (int i = 4; i > 0; i--)
    rename(string(fullpath + ".old." + ToString(i)).c_str(), string(fullpath + ".old." + ToString(i + 1)).c_str());

  rename(fullpath.c_str(), string(fullpath + ".old.1").c_str());

  //open the logfile in append mode
  logfile.open(fullpath.c_str());
  if (logfile.fail())
  {
    PrintError("unable to open " + fullpath + ":\n" + GetErrno());
    return false;
  }

  Log("start of log %s", fullpath.c_str());

  return true;
}

//we only want the function name and the namespace, so we search for '(' and get the string before that
string PruneFunction(string function)
{
  size_t parenpos = function.find('(');
  size_t spacepos = function.rfind(' ', parenpos);

  if (parenpos == string::npos || spacepos == string::npos)
    return function;
  else
    return function.substr(spacepos + 1, parenpos - spacepos - 1);
}

void SetLogFile(std::string filename)
{
  CLock lock(g_logmutex);

  if (!g_logfile.is_open())
  {
    if (!InitLog(filename, g_logfile))
    {
      printlogtofile = false;
    }
  }
}

void PrintLog(const char* fmt, const char* function, bool error, ...)
{
  string                logstr;
  string                funcstr;
  va_list               args;
  int                   nrspaces;

  static int            logbuffsize = 128; //size of the buffer
  static char*          logbuff = reinterpret_cast<char*>(malloc(logbuffsize)); //buffer for vsnprintf
  static vector<string> logstrings;      //we save any log lines here while the log isn't open

  CLock lock(g_logmutex);
  
  va_start(args, error);

  //print to the logbuffer and check if our buffer is large enough
  int neededbuffsize = vsnprintf(logbuff, logbuffsize, fmt, args);
  if (neededbuffsize + 1 > logbuffsize)
  {
    logbuffsize = neededbuffsize + 1;
    logbuff = reinterpret_cast<char*>(realloc(logbuff, logbuffsize)); //resize the buffer to the needed size

    va_end(args); //need to reinit or we will crash
    va_start(args, error);

    vsnprintf(logbuff, logbuffsize, fmt, args);                       //write to the buffer again
  }
  
  va_end(args);

  if (error)
    logstr += "ERROR: ";

  logstr += logbuff;

  funcstr = "(" + PruneFunction(function) + ")";
  nrspaces = 32 - funcstr.length();
  if (nrspaces > 0)
    funcstr.insert(funcstr.length(), nrspaces, ' ');
  
  if (g_logfile.is_open() && printlogtofile)
  {
    //print any saved log lines
    if (!logstrings.empty())
    {
      for (int i = 0; i < logstrings.size(); i++)
      {
        g_logfile << logstrings[i] << flush;
      }
      logstrings.clear();
    }
    //write the string to the logfile
    g_logfile << GetStrTime() << " " << funcstr << " " << logstr << '\n' << flush;
  }
  else if (printlogtofile)
  {
    //save the log line if the log isn't open yet
    logstrings.push_back(GetStrTime() + " " + funcstr + " " + logstr + '\n');
  }

  //print to stdout when requested
  if (logtostderr)
    cerr << funcstr << logstr << '\n' << flush;
}
