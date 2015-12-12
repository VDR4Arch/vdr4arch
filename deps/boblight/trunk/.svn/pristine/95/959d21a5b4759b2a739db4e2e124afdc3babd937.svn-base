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

#include "flagmanager-v4l.h"
#include "config.h"
#include "util/misc.h"

using namespace std;

CFlagManagerV4l::CFlagManagerV4l()
{
  //c = device, w == widthxheight, v = video standard, i = input, d = debug mode, e = codec
  m_flags += "c:w:v:i:d::ne:";

  //default device
  m_device = "/dev/video0";

  //default size
  m_width = 64;
  m_height = 64;

  //sync mode enabled by default
  m_sync = true;

  //channel of -1 means ffmpeg doesn't change it
  m_channel = -1;

  //emptpy standard meands ffmpeg doesn't change it
  m_standard = NULL;

  m_checksignal = false;
  
  m_debug = false;
  m_debugdpy = NULL;
}

void CFlagManagerV4l::ParseFlagsExtended(int& argc, char**& argv, int& c, char*& optarg)
{
  if (c == 'c')
  {
    m_device = optarg;
  }
  else if (c == 'w')
  {
    if (sscanf(optarg, "%ix%i", &m_width, &m_height) != 2 || m_width < 1 || m_height < 1)
    {
      throw string("Wrong value " + string(optarg) + " for widthxheight");
    }
  }
  else if (c == 'v')
  {
    m_strstandard = optarg;
    m_standard = m_strstandard.c_str();
  }
  else if (c == 'i')
  {
    if (!StrToInt(string(optarg), m_channel))
    {
      throw string("Wrong value " + string(optarg) + " for channel");
    }
  }
  else if (c == 'd')
  {
    m_debug = true;
    if (optarg)      //optional debug dpy
    {
      m_strdebugdpy = optarg;
      m_debugdpy = m_strdebugdpy.c_str();
    }
  }
  else if (c == 'n')
  {
    m_checksignal = true;
  }
  else if (c == 'e')
  {
    m_customcodec = optarg;
  }
}

void CFlagManagerV4l::PrintHelpMessage()
{
  cout << "Usage: boblight-v4l [OPTION]\n";
  cout << "\n";
  cout << "  options:\n";
  cout << "\n";
  cout << "  -p  priority, from 0 to 255, default is 128\n";
  cout << "  -s  address:[port], set the address and optional port to connect to\n";
  cout << "  -o  add libboblight option, syntax: [light:]option=value\n";
  cout << "  -l  list libboblight options\n";
  cout << "  -f  fork\n";
  cout << "  -c  set the device to use, default is /dev/video0\n";
  cout << "  -w  widthxheight of the captured image, example: -w 400x300\n";
  cout << "  -v  video standard\n";
  cout << "  -i  video input number\n";
  cout << "  -n  only turn on boblight client when there's a video signal\n";
  cout << "  -e  use custom codec, default is video4linux2 or video4linux\n";
  cout << "  -d  debug mode\n";
  cout << "  -y  set the sync mode, default is on, valid options are \"on\" and \"off\"\n";
  cout << "\n";
}
