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

#include "flagmanager-constant.h"
#include "util/misc.h"
#include "config.h"

using namespace std;

void CFlagManagerConstant::PostGetopt(int optind, int argc, char** argv)
{
  //check if a color was given
  if (optind == argc)
    throw string("no color given");
  
  //check if the color can be loaded, should be in RRGGBB hex notation
  if (!HexStrToInt(argv[optind], m_color) || m_color & 0xFF000000)
    throw string("wrong value " + ToString(argv[optind]) + " for color");
}

void CFlagManagerConstant::PrintHelpMessage()
{
  cout << "Usage: boblight-constant [OPTION] color\n";
  cout << "\n";
  cout << "  color is in RRGGBB hex notation\n";
  cout << "\n";
  cout << "  options:\n";
  cout << "\n";
  cout << "  -p  priority, from 0 to 255, default is 128\n";
  cout << "  -s  address[:port], set the address and optional port to connect to\n";
  cout << "  -o  add libboblight option, syntax: [light:]option=value\n";
  cout << "  -l  list libboblight options\n";
  cout << "  -f  fork\n";
  cout << "\n";
}
