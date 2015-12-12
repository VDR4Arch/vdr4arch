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

#include "boblight.h"
#include "boblight_client.h"

using namespace boblight;

//C wrapper for C++ class

void* boblight_init()
{
  CBoblight* boblight = new CBoblight;
  return reinterpret_cast<void*>(boblight);
}

void boblight_destroy(void* vpboblight)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  delete boblight;
}

int boblight_connect(void* vpboblight, const char* address, int port, int usectimeout)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->Connect(address, port, usectimeout);
}

int boblight_setpriority(void* vpboblight, int priority)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->SetPriority(priority);
}

const char* boblight_geterror(void* vpboblight)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->GetError();
}

int boblight_getnrlights(void* vpboblight)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->GetNrLights();
}

const char* boblight_getlightname(void* vpboblight, int lightnr)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->GetLightName(lightnr);
}

int boblight_getnroptions(void* vpboblight)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->GetNrOptions();
}

const char* boblight_getoptiondescript(void* vpboblight, int option)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->GetOptionDescription(option);
}

int boblight_setoption(void* vpboblight, int lightnr, const char* option)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->SetOption(lightnr, option);
}

int boblight_getoption(void* vpboblight, int lightnr, const char* option, const char** output)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->GetOption(lightnr, option, output);
}

void boblight_setscanrange(void* vpboblight, int width, int height)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  boblight->SetScanRange(width, height);
}

int boblight_addpixel(void* vpboblight, int lightnr, int* rgb)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->AddPixel(lightnr, rgb);
}

void boblight_addpixelxy(void* vpboblight, int x, int y, int* rgb)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  boblight->AddPixel(rgb, x, y);
}

int boblight_sendrgb(void* vpboblight, int sync, int* outputused)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->SendRGB(sync, outputused);
}

int boblight_ping(void* vpboblight, int* outputused)
{
  CBoblight* boblight = reinterpret_cast<CBoblight*>(vpboblight);
  return boblight->Ping(outputused, true);
}
