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
#include <fstream>
#include <sched.h>

#include "util/log.h"
#include "util/misc.h"
#include "configuration.h"

#include "device/devicepopen.h"
#include "device/deviceltbl.h"

#ifdef HAVE_LIBUSB
  #include "device/devicelightpack.h"
  #include "device/deviceibelight.h"
#endif

#ifdef HAVE_OLA
  #include "device/deviceola.h"
#endif

using namespace std;

#define SECTNOTHING 0
#define SECTGLOBAL  1
#define SECTDEVICE  2
#define SECTCOLOR   3
#define SECTLIGHT   4

//builds the config
bool CConfig::LoadConfigFromFile(string file)
{
  int linenr = 0;
  int currentsection = SECTNOTHING;

  m_filename = file;
  
  Log("opening %s", file.c_str());

  //try to open the config file
  ifstream configfile(file.c_str());
  if (configfile.fail())
  {
    LogError("%s: %s", file.c_str(), GetErrno().c_str());
    return false;
  }

  //read lines from the config file and store them in the appropriate sections
  while (!configfile.eof())
  {
    string buff;
    getline(configfile, buff);
    linenr++;
    if (configfile.fail())
    {
      if (!configfile.eof())
        LogError("reading %s line %i: %s", file.c_str(), linenr, GetErrno().c_str());
      break;
    }

    string line = buff;
    string key;
    //if the line doesn't have a word it's not important
    if (!GetWord(line, key))
      continue;

    //ignore comments
    if (key.substr(0, 1) == "#")
      continue;

    //check if we entered a section
    if (key == "[global]")
    {
      currentsection = SECTGLOBAL;
      continue;
    }
    else if (key == "[device]")
    {
      currentsection = SECTDEVICE;
      m_devicelines.resize(m_devicelines.size() + 1);
      continue;
    }
    else if (key == "[color]")
    {
      currentsection = SECTCOLOR;
      m_colorlines.resize(m_colorlines.size() + 1);
      continue;
    }
    else if (key == "[light]")
    {
      currentsection = SECTLIGHT;
      m_lightlines.resize(m_lightlines.size() + 1);
      continue;
    }

    //we're not in a section
    if (currentsection == SECTNOTHING)
      continue;

    CConfigLine configline(buff, linenr);

    //store the config line in the appropriate section
    if (currentsection == SECTGLOBAL)
    {
      m_globalconfiglines.push_back(configline);
    }
    else if (currentsection == SECTDEVICE)
    {
      m_devicelines.back().lines.push_back(configline);
    }
    else if (currentsection == SECTCOLOR)
    {
      m_colorlines.back().lines.push_back(configline);
    }
    else if (currentsection == SECTLIGHT)
    {
      m_lightlines.back().lines.push_back(configline);
    }
  }

  //PrintConfig();

  return true;
}

void CConfig::PrintConfig()
{
  Log("[global]");

  for (int i = 0; i < m_globalconfiglines.size(); i++)
  {
    //replace any tabs with spaces
    string line = m_globalconfiglines[i].line;
    TabsToSpaces(line);

    //print the line to the log
    Log("%i %s", m_globalconfiglines[i].linenr, line.c_str());
  }

  Log("%zu devices", m_devicelines.size());
  for (int i = 0; i < m_devicelines.size(); i++)
  {
    Log("[device] %i", i);
    for (int j = 0; j < m_devicelines[i].lines.size(); j++)
    {
      string line = m_devicelines[i].lines[j].line;
      TabsToSpaces(line);
      Log("%i %s", m_devicelines[i].lines[j].linenr, line.c_str());
    }
  }

  Log("%zu colors", m_colorlines.size());
  for (int i = 0; i < m_colorlines.size(); i++)
  {
    Log("[color] %i", i);
    for (int j = 0; j < m_colorlines[i].lines.size(); j++)
    {
      string line = m_colorlines[i].lines[j].line;
      TabsToSpaces(line);
      Log("%i %s", m_colorlines[i].lines[j].linenr, line.c_str());
    }
  }

  Log("%zu lights", m_lightlines.size());
  for (int i = 0; i < m_lightlines.size(); i++)
  {
    Log("[light] %i", i);
    for (int j = 0; j < m_lightlines[i].lines.size(); j++)
    {
      string line = m_lightlines[i].lines[j].line;
      TabsToSpaces(line);
      Log("%i %s", m_lightlines[i].lines[j].linenr, line.c_str());
    }
  }
}

void CConfig::TabsToSpaces(std::string& line)
{
  size_t pos = line.find('\t');
  while (pos != string::npos)
  {
    line.replace(pos, 1, 1, ' ');
    pos++;
    if (pos >= line.size()) break;
    pos = line.find('\t', pos);
  }
}

//checks lines in the config file to make sure the syntax is correct
bool CConfig::CheckConfig()
{
  bool valid = true;
  Log("checking config lines");

  if (!CheckGlobalConfig())
    valid = false;

  if (!CheckDeviceConfig())
    valid = false;

  if (!CheckColorConfig())
    valid = false;

  if (!CheckLightConfig())
    valid = false;
  
  if (valid)
    Log("config lines valid");
  
  return valid;
}

bool CConfig::CheckGlobalConfig()
{
  bool valid = true;
  
  for (int i = 0; i < m_globalconfiglines.size(); i++)
  {
    string line = m_globalconfiglines[i].line;
    string key;
    string value;

    GetWord(line, key); //we already checked each line starts with one word

    if (!GetWord(line, value)) //every line here needs to have another word
    {
      LogError("%s line %i section [global]: no value for key %s", m_filename.c_str(), m_globalconfiglines[i].linenr, key.c_str());
      valid = false;
      continue;
    }

    if (key == "interface")
    {
      continue; //not much to check here
    }
    else if (key == "port") //check tcp/ip port
    {
      int port;
      if (!StrToInt(value, port) || port < 0 || port > 65535)
      {
        LogError("%s line %i section [global]: wrong value %s for key %s",
                 m_filename.c_str(), m_globalconfiglines[i].linenr, value.c_str(), key.c_str());
        valid = false;
      }
    }
    else //we don't know this one
    {
      LogError("%s line %i section [global]: unknown key %s", m_filename.c_str(), m_globalconfiglines[i].linenr, key.c_str());
      valid = false;
    }
  }

  return valid;
}

bool CConfig::CheckDeviceConfig()
{
  bool valid = true;

  if (m_devicelines.size() == 0)
  {
    LogError("%s no devices defined", m_filename.c_str());
    return false;
  }

  for (int i = 0; i < m_devicelines.size(); i++)
  {
    for (int j = 0; j < m_devicelines[i].lines.size(); j++)
    {
      string line = m_devicelines[i].lines[j].line;
      int linenr = m_devicelines[i].lines[j].linenr;
      string key;
      string value;

      GetWord(line, key); //we already checked each line starts with one word

      if (!GetWord(line, value)) //every line here needs to have another word
      {
        LogError("%s line %i section [device]: no value for key %s", m_filename.c_str(), linenr, key.c_str());
        valid = false;
        continue;
      }

      if (key == "name" || key == "output" || key == "type" || key == "serial")
      {
        continue; //can't check these here
      }
      else if (key == "rate" || key == "channels" || key == "interval" || key == "period" ||
               key == "bits" || key == "delayafteropen" || key == "max" || key == "precision")
      { //these are of type integer not lower than 1
        int64_t ivalue;
        if (!StrToInt(value, ivalue) || ivalue < 1 || (key == "bits" && ivalue > 32) || (key == "max" && ivalue > 0xFFFFFFFF))
        {
          LogError("%s line %i section [device]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
          valid = false;
        }          
      }
      else if (key == "threadpriority")
      {
        int64_t ivalue;
        if (!StrToInt(value, ivalue))
        {
          LogError("%s line %i section [device]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
          valid = false;
        }

        int priomax = sched_get_priority_max(SCHED_FIFO);
        int priomin = sched_get_priority_min(SCHED_FIFO);
        if (ivalue > priomax || ivalue < priomin)
        {
          LogError("%s line %i section [device]: threadpriority must be between %i and %i",
                   m_filename.c_str(), linenr, priomin, priomax);
          valid = false;
        }
      }
      else if (key == "prefix" || key == "postfix")
      { //this is in hex from 00 to FF, separated by spaces, like: prefix FF 7F A0 22
        int ivalue;
        while(1)
        {
          if (!HexStrToInt(value, ivalue) || (ivalue > 0xFF))
          {
            LogError("%s line %i section [device]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
            valid = false;
          }
          if (!GetWord(line, value))
            break;
        }
      }
      else if (key == "latency")//this is a double
      {
        double latency;
        if (!StrToFloat(value, latency) || latency <= 0.0)
        {
          LogError("%s line %i section [device]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
          valid = false;
        }
      }
      else if (key == "allowsync" || key == "debug")//bool
      {
        bool bValue;
        if (!StrToBool(value, bValue))
        {
          LogError("%s line %i section [device]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
          valid = false;
        }
      }
      else if (key == "bus" || key == "address") //int, 0 to 255
      {
        int ivalue;
        if (!StrToInt(value, ivalue) || ivalue < 0 || ivalue > 255)
        {
          LogError("%s line %i section [device]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
          valid = false;
        }
      }
      else //don't know this one
      {
        LogError("%s line %i section [device]: unknown key %s", m_filename.c_str(), linenr, key.c_str());
        valid = false;
      }      
    }
  }

  return valid;
}

bool CConfig::CheckColorConfig()
{
  bool valid = true;

  if (m_colorlines.size() == 0)
  {
    LogError("%s no colors defined", m_filename.c_str());
    return false;
  }

  for (int i = 0; i < m_colorlines.size(); i++)
  {
    for (int j = 0; j < m_colorlines[i].lines.size(); j++)
    {
      string line = m_colorlines[i].lines[j].line;
      int linenr = m_colorlines[i].lines[j].linenr;
      string key;
      string value;

      GetWord(line, key); //we already checked each line starts with one word

      if (!GetWord(line, value)) //every line here needs to have another word
      {
        LogError("%s line %i section [color]: no value for key %s", m_filename.c_str(), linenr, key.c_str());
        valid = false;
        continue;
      }

      if (key == "name")
      {
        continue;
      }
      else if (key == "gamma" || key == "adjust" || key == "blacklevel")
      { //these are floats from 0.0 to 1.0, except gamma which is from 0.0 and up
        float fvalue;
        if (!StrToFloat(value, fvalue) || fvalue < 0.0 || (key != "gamma" && fvalue > 1.0))
        {
          LogError("%s line %i section [color]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
          valid = false;
        }
      }
      else if (key == "rgb")
      { //rgb lines in hex notation, like: rgb FF0000 for red and rgb 0000FF for blue
        int rgb;
        if (!HexStrToInt(value, rgb) || (rgb & 0xFF000000))
        {
          LogError("%s line %i section [color]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
          valid = false;
        }
      }
      else //don't know this one
      {
        LogError("%s line %i section [color]: unknown key %s", m_filename.c_str(), linenr, key.c_str());
        valid = false;
      }      
    }
  }

  return valid;
}

bool CConfig::CheckLightConfig()
{
  bool valid = true;

  if (m_lightlines.size() == 0)
  {
    LogError("%s no lights defined", m_filename.c_str());
    return false;
  }

  for (int i = 0; i < m_lightlines.size(); i++)
  {
    for (int j = 0; j < m_lightlines[i].lines.size(); j++)
    {
      string line = m_lightlines[i].lines[j].line;
      int linenr = m_lightlines[i].lines[j].linenr;
      string key;
      string value;

      GetWord(line, key); //we already checked each line starts with one word

      if (!GetWord(line, value)) //every line here needs to have another word
      {
        LogError("%s line %i section [light]: no value for key %s", m_filename.c_str(), linenr, key.c_str());
        valid = false;
        continue;
      }

      if (key == "name")
      {
        continue;
      }
      else if (key == "vscan" || key == "hscan") //check the scanrange, should be two floats from 0.0 to 100.0
      {
        string scanrange;
        float scan[2];
        if (!GetWord(line, scanrange))
        {
          LogError("%s line %i section [light]: not enough values for key %s", m_filename.c_str(), linenr, key.c_str());
          valid = false;
          continue;
        }

        scanrange = value + " " + scanrange;

        if (sscanf(scanrange.c_str(), "%f %f", scan, scan + 1) != 2
            || scan[0] < 0.0 || scan[0] > 100.0 || scan[1] < 0.0 || scan[1] > 100.0 || scan[0] > scan[1])
        {
          LogError("%s line %i section [light]: wrong value %s for key %s", m_filename.c_str(), linenr, scanrange.c_str(), key.c_str());
          valid = false;
          continue;
        }
      }
      else if (key == "color")
      { //describes a color for a light, on a certain channel of a device
        //we can only check if it has enough keys and channel is a positive int from 1 or higher
        int k;
        for (k = 0; k < 2; k++)
        {
          if (!GetWord(line, value))
          {
            LogError("%s line %i section [light]: not enough values for key %s", m_filename.c_str(), linenr, key.c_str());
            valid = false;
            break;
          }
        }
        if (k == 2)
        {
          int channel;
          if (!StrToInt(value, channel) || channel <= 0)
          {
            LogError("%s line %i section [light]: wrong value %s for key %s", m_filename.c_str(), linenr, value.c_str(), key.c_str());
            valid = false;
          }
        }
      }
      else //don't know this one
      {
        LogError("%s line %i section [light]: unknown key %s", m_filename.c_str(), linenr, key.c_str());
        valid = false;
      }      
    }
  }

  return valid;
}

//gets a config line that starts with key
int CConfig::GetLineWithKey(std::string key, std::vector<CConfigLine>& lines, std::string& line)
{
  for (int i = 0; i < lines.size(); i++)
  {
    string word;
    line = lines[i].line;
    GetWord(line, word);

    if (word == key)
    {
      return lines[i].linenr;
    }
  }

  return -1;
}

//builds the config
bool CConfig::BuildConfig(CClientsHandler& clients, std::vector<CDevice*>& devices, std::vector<CLight>& lights)
{
  Log("building config");
  
  BuildClientsHandlerConfig(clients);

  vector<CColor> colors;
  if (!BuildColorConfig(colors))
    return false;

  if (!BuildDeviceConfig(devices, clients))
    return false;

  if (!BuildLightConfig(lights, devices, colors))
    return false;
  
  Log("built config successfully");

  return true;
}

void CConfig::BuildClientsHandlerConfig(CClientsHandler& clients)
{
  //set up where to bind the listening socket
  //config for this should already be valid here, of course we can't check yet if the interface actually exists
  string interface; //empty string means bind to *
  int port = 19333; //default port
  for (int i = 0; i < m_globalconfiglines.size(); i++)
  {
    string line = m_globalconfiglines[i].line;
    string word;
    GetWord(line, word);

    if (word == "interface")
    {
      GetWord(line, interface);
    }
    else if (word == "port")
    {
      GetWord(line, word);
      StrToInt(word, port);
    }
  }
  clients.SetInterface(interface, port);
}

bool CConfig::BuildColorConfig(std::vector<CColor>& colors)
{
  for (int i = 0; i < m_colorlines.size(); i++)
  {
    CColor color;
    for (int j = 0; j < m_colorlines[i].lines.size(); j++)
    {
      string line = m_colorlines[i].lines[j].line;
      string key, value;

      GetWord(line, key);
      GetWord(line, value);

      if (key == "name")
      {
        color.SetName(value);
      }
      else if (key == "rgb")
      {
        int irgb;
        float frgb[3];
        HexStrToInt(value, irgb);

        for (int k = 0; k < 3; k++)
          frgb[k] = (float)((irgb >> ((2 - k) * 8)) & 0xFF) / 255.0;

        color.SetRgb(frgb);
      }
      else if (key == "gamma")
      {
        float gamma;
        ConvertFloatLocale(value);
        StrToFloat(value, gamma);
        color.SetGamma(gamma);
      }
      else if (key == "adjust")
      {
        float adjust;
        ConvertFloatLocale(value);
        StrToFloat(value, adjust);
        color.SetAdjust(adjust);
      }
      else if (key == "blacklevel")
      {
        float blacklevel;
        ConvertFloatLocale(value);
        StrToFloat(value, blacklevel);
        color.SetBlacklevel(blacklevel);
      }
    }

    //we need at least a name for a color
    if (color.GetName().empty())
    {
      LogError("%s: color %i has no name", m_filename.c_str(), i + 1);
      return false;
    }

    colors.push_back(color);
  }

  return true;
}

//builds a pool of devices
bool CConfig::BuildDeviceConfig(std::vector<CDevice*>& devices, CClientsHandler& clients)
{
  for (int i = 0; i < m_devicelines.size(); i++)
  {
    string line;
    int linenr = GetLineWithKey("type", m_devicelines[i].lines, line);
    string type;

    GetWord(line, type);

    if (type == "popen")
    {
      CDevice* device = NULL;
      if (!BuildPopen(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
    }
    else if (type == "momo" || type == "atmo" || type == "karate" || type == "sedu")
    {
      CDevice* device = NULL;
      if (!BuildRS232(device, i, clients, type))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
    }
    else if (type == "ltbl")
    {
      CDevice* device = NULL;
      if (!BuildLtbl(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
    }
    else if (type == "ola")
    {
#ifdef HAVE_OLA
      CDevice* device = NULL;
      if (!BuildOla(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
#else
      LogError("%s line %i: boblightd was built without ola, recompile with enabled ola support",
               m_filename.c_str(), linenr);
      return false;
#endif
    }
    else if (type == "sound")
    {
#ifdef HAVE_LIBPORTAUDIO
      CDevice* device = NULL;
      if (!BuildSound(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
#else
      LogError("%s line %i: boblightd was built without portaudio, no support for sound devices",
               m_filename.c_str(), linenr);
      return false;
#endif
    }
    else if (type == "dioder")
    {
      CDevice* device = NULL;
      if (!BuildDioder(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
    }
    else if (type == "ambioder")
    {
      CDevice* device = NULL;
      if (!BuildAmbioder(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
    }
    else if (type == "ibelight")
    {
#ifdef HAVE_LIBUSB
      CDevice* device = NULL;
      if (!BuildiBeLight(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
#else
      LogError("%s line %i: boblightd was built without libusb, no support for ibelight devices",
               m_filename.c_str(), linenr);
      return false;
#endif
    }
    else if (type == "lightpack")
    {
#ifdef HAVE_LIBUSB
      CDevice* device = NULL;
      if (!BuildLightpack(device, i, clients))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
#else
      LogError("%s line %i: boblightd was built without libusb, no support for lightpack devices",
               m_filename.c_str(), linenr);
      return false;
#endif
    }
    else if (type == "lpd8806" || type == "ws2801")
    {
#ifdef HAVE_LINUX_SPI_SPIDEV_H
      CDevice* device = NULL;
      if (!BuildSPI(device, i, clients, type))
      {
        if (device)
          delete device;
        return false;
      }
      devices.push_back(device);
#else
      LogError("%s line %i: boblightd was built without spi, no support for lpd8806 devices",
               m_filename.c_str(), linenr);
      return false;
#endif
    }
    else
    {
      LogError("%s line %i: unknown type %s", m_filename.c_str(), linenr, type.c_str());
      return false;
    }
  }

  return true;
}

//builds a pool of lights
bool CConfig::BuildLightConfig(std::vector<CLight>& lights, std::vector<CDevice*>& devices, std::vector<CColor>& colors)
{
  CLight globallight; //default values

  for (int i = 0; i < m_lightlines.size(); i++)
  {
    CLight light = globallight;

    if (!SetLightName(light, m_lightlines[i].lines, i))
      return false;

    SetLightScanRange(light, m_lightlines[i].lines);

    //check the colors on a light
    for (int j = 0; j < m_lightlines[i].lines.size(); j++)
    {
      string line = m_lightlines[i].lines[j].line;
      string key;
      GetWord(line, key);

      if (key != "color")
        continue;

      //we already checked these in the syntax check
      string colorname, devicename, devicechannel;
      GetWord(line, colorname);
      GetWord(line, devicename);
      GetWord(line, devicechannel);

      bool colorfound = false;
      for (int k = 0; k < colors.size(); k++)
      {
        if (colors[k].GetName() == colorname)
        {
          colorfound = true;
          light.AddColor(colors[k]);
          break;
        }
      }
      if (!colorfound) //this color doesn't exist
      {
        LogError("%s line %i: no color with name %s", m_filename.c_str(), m_lightlines[i].lines[j].linenr, colorname.c_str());
        return false;
      }

      int ichannel;
      StrToInt(devicechannel, ichannel);

      //loop through the devices, check if one with this name exists and if the channel on it exists
      bool devicefound = false;
      for (int k = 0; k < devices.size(); k++)
      {
        if (devices[k]->GetName() == devicename)
        {
          if (ichannel > devices[k]->GetNrChannels())
          {
            LogError("%s line %i: channel %i wanted but device %s has %i channels", m_filename.c_str(),
                m_lightlines[i].lines[j].linenr, ichannel, devices[k]->GetName().c_str(), devices[k]->GetNrChannels());
            return false;
          }
          devicefound = true;
          CChannel channel;
          channel.SetColor(light.GetNrColors() - 1);
          channel.SetLight(i);
          devices[k]->SetChannel(channel, ichannel - 1);
          break;
        }
      }
      if (!devicefound)
      {
        LogError("%s line %i: no device with name %s", m_filename.c_str(), m_lightlines[i].lines[j].linenr, devicename.c_str());
        return false;
      }
    }
    lights.push_back(light);
  }

  return true;
}

#ifdef HAVE_OLA
bool CConfig::BuildOla(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  device = new CDeviceOla(clients);

  if (!SetDeviceName(device, devicenr))
    return false;

  if (!SetDeviceOutput(device, devicenr))
    return false;

  if (!SetDeviceChannels(device, devicenr))
    return false;

  if (!SetDeviceInterval(device, devicenr))
    return false;

  SetDeviceThreadPriority(device, devicenr);

  device->SetType(OLA);

  return true;
}
#endif

bool CConfig::BuildPopen(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  device = new CDevicePopen(clients);

  if (!SetDeviceName(device, devicenr))
    return false;

  if (!SetDeviceOutput(device, devicenr))
    return false;

  if (!SetDeviceChannels(device, devicenr))
    return false;

  if (!SetDeviceInterval(device, devicenr))
    return false;

  SetDeviceAllowSync(device, devicenr);
  SetDeviceDebug(device, devicenr);
  SetDeviceDelayAfterOpen(device, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  device->SetType(POPEN);
  
  return true;
}

bool CConfig::BuildRS232(CDevice*& device, int devicenr, CClientsHandler& clients, const std::string& type)
{
  CDeviceRS232* rs232device = new CDeviceRS232(clients);
  device = rs232device;

  if (!SetDeviceName(rs232device, devicenr))
    return false;

  if (!SetDeviceOutput(rs232device, devicenr))
    return false;

  if (!SetDeviceChannels(rs232device, devicenr))
    return false;

  if (!SetDeviceRate(rs232device, devicenr))
    return false;

  if (!SetDeviceInterval(rs232device, devicenr))
    return false;

  SetDeviceAllowSync(device, devicenr);
  SetDeviceDebug(device, devicenr);
  SetDeviceDelayAfterOpen(device, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  bool hasbits = SetDeviceBits(rs232device, devicenr);
  bool hasmax  = SetDeviceMax(rs232device, devicenr);
  if (hasbits && hasmax)
  {
    LogError("%s: device %s has both bits and max set", m_filename.c_str(), rs232device->GetName().c_str());
    return false;
  }

  if (type == "momo")
  {
    device->SetType(MOMO);
    SetDevicePrefix(rs232device, devicenr);
    SetDevicePostfix(rs232device, devicenr);
  }
  else if (type == "atmo")
  {
    device->SetType(ATMO);
  }
  else if (type == "karate")
  {
    device->SetType(KARATE);
  }
  else if (type == "sedu")
  {
    device->SetType(SEDU);
  }
  
  return true;
}

bool CConfig::BuildLtbl(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  device = new CDeviceLtbl(clients);

  if (!SetDeviceName(device, devicenr))
    return false;

  if (!SetDeviceOutput(device, devicenr))
    return false;

  if (!SetDeviceChannels(device, devicenr))
    return false;

  if (!SetDeviceRate(device, devicenr))
    return false;

  if (!SetDeviceInterval(device, devicenr))
    return false;

  SetDeviceAllowSync(device, devicenr);
  SetDeviceDebug(device, devicenr);
  SetDeviceDelayAfterOpen(device, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  device->SetType(LTBL);
  
  return true;
}

#ifdef HAVE_LIBPORTAUDIO
bool CConfig::BuildSound(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  CDeviceSound* sounddevice = new CDeviceSound(clients);
  device = sounddevice;

  if (!SetDeviceName(sounddevice, devicenr))
    return false;

  if (!SetDeviceOutput(sounddevice, devicenr))
    return false;

  if (!SetDeviceChannels(sounddevice, devicenr))
    return false;

  if (!SetDeviceRate(sounddevice, devicenr))
    return false;

  if (!SetDevicePeriod(sounddevice, devicenr))
    return false;

  SetDeviceLatency(sounddevice, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  sounddevice->SetType(SOUND);

  //check if output is in api:device format
  int pos = sounddevice->GetOutput().find(':');
  if (pos == string::npos || sounddevice->GetOutput().size() == pos)
  {
    LogError("%s: device %s output \"%s\" is not in api:device format",
        m_filename.c_str(), sounddevice->GetName().c_str(), sounddevice->GetOutput().c_str());
    return false;
  }

  return true;
}
#endif

#ifdef HAVE_LIBUSB
bool CConfig::BuildiBeLight(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  CDeviceiBeLight* ibedevice = new CDeviceiBeLight(clients);
  device = ibedevice;

  if (!SetDeviceName(ibedevice, devicenr))
    return false;

  if (!SetDeviceChannels(ibedevice, devicenr))
    return false;

  if (!SetDeviceInterval(device, devicenr))
    return false;

  SetDeviceBus(ibedevice, devicenr);
  SetDeviceAddress(ibedevice, devicenr);
  SetDeviceAllowSync(device, devicenr);
  SetDeviceDebug(device, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  ibedevice->SetType(IBELIGHT);

  return true;
}
#endif

#ifdef HAVE_LIBUSB
bool CConfig::BuildLightpack(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  CDeviceLightpack* lightpackdevice = new CDeviceLightpack(clients);
  device = lightpackdevice;

  if (!SetDeviceName(device, devicenr))
    return false;

  if (!SetDeviceChannels(device, devicenr))
    return false;

  if (!SetDeviceInterval(device, devicenr))
    return false;

  SetDeviceBus(lightpackdevice, devicenr);
  SetDeviceAddress(lightpackdevice, devicenr);
  SetSerial(lightpackdevice, devicenr);
  SetDeviceAllowSync(lightpackdevice, devicenr);
  SetDeviceDebug(lightpackdevice, devicenr);
  SetDeviceThreadPriority(lightpackdevice, devicenr);

  device->SetType(LIGHTPACK);

  return true;
}
#endif


bool CConfig::BuildDioder(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  CDeviceDioder* dioderdevice = new CDeviceDioder(clients);

  device = dioderdevice;

  if (!SetDeviceName(dioderdevice, devicenr))
    return false;

  if (!SetDeviceOutput(dioderdevice, devicenr))
    return false;

  if (!SetDeviceChannels(dioderdevice, devicenr))
    return false;

  if (!SetDeviceRate(dioderdevice, devicenr))
    return false;

  if (!SetDeviceInterval(dioderdevice, devicenr))
    return false;

  SetDeviceAllowSync(device, devicenr);
  SetDeviceDebug(device, devicenr);
  SetDeviceDelayAfterOpen(device, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  device->SetType(DIODER);
  
  return true;

}

bool CConfig::BuildAmbioder(CDevice*& device, int devicenr, CClientsHandler& clients)
{
  CDeviceAmbioder* ambioderdevice = new CDeviceAmbioder(clients);

  device = ambioderdevice;

  if (!SetDeviceName(ambioderdevice, devicenr))
    return false;

  if (!SetDeviceOutput(ambioderdevice, devicenr))
    return false;

  if (!SetDeviceChannels(ambioderdevice, devicenr))
    return false;

  if (!SetDeviceRate(ambioderdevice, devicenr))
    return false;

  if (!SetDeviceInterval(ambioderdevice, devicenr))
    return false;

  if (!SetDevicePrecision(ambioderdevice, devicenr))
    return false;

  SetDeviceAllowSync(device, devicenr);
  SetDeviceDebug(device, devicenr);
  SetDeviceDelayAfterOpen(device, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  device->SetType(AMBIODER);

  return true;

}

bool CConfig::SetDevicePrecision(CDeviceAmbioder*& device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("precision", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return false;

  GetWord(line, strvalue);

  int precision;
  StrToInt(strvalue, precision);

  if(!device->SetPrecision(precision))
    return false;

  return true;
}

#ifdef HAVE_LINUX_SPI_SPIDEV_H
bool CConfig::BuildSPI(CDevice*& device, int devicenr, CClientsHandler& clients, const std::string& type)
{
  CDeviceSPI* spidevice = new CDeviceSPI(clients);
  device = spidevice;

  if (!SetDeviceName(spidevice, devicenr))
    return false;

  if (!SetDeviceOutput(spidevice, devicenr))
    return false;

  if (!SetDeviceChannels(spidevice, devicenr))
    return false;

  if (!SetDeviceInterval(spidevice, devicenr))
    return false;

  if (!SetDeviceRate(spidevice, devicenr))
    return false;

  SetDeviceAllowSync(device, devicenr);
  SetDeviceDebug(device, devicenr);
  SetDeviceThreadPriority(device, devicenr);

  if (type == "lpd8806")
    device->SetType(LPD8806);
  else if (type == "ws2801")
    device->SetType(WS2801);

  return true;
}
#endif

bool CConfig::SetDeviceName(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("name", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    LogError("%s: device %i has no name", m_filename.c_str(), devicenr + 1);
    return false;
  }
  GetWord(line, strvalue);
  device->SetName(strvalue);

  return true;
}

bool CConfig::SetDeviceOutput(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("output", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    LogError("%s: device %s has no output", m_filename.c_str(), device->GetName().c_str());
    return false;
  }
  GetWord(line, strvalue);
  device->SetOutput(strvalue + line);

  return true;
}

bool CConfig::SetDeviceChannels(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("channels", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    LogError("%s: device %s has no channels", m_filename.c_str(), device->GetName().c_str());
    return false;
  }
  GetWord(line, strvalue);

  int nrchannels;
  StrToInt(strvalue, nrchannels);
  device->SetNrChannels(nrchannels);

  return true;
}  

bool CConfig::SetDeviceRate(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("rate", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    LogError("%s: device %s has no rate", m_filename.c_str(), device->GetName().c_str());
    return false;
  }
  GetWord(line, strvalue);

  int rate;
  StrToInt(strvalue, rate);
  device->SetRate(rate);

  return true;
}

bool CConfig::SetDeviceInterval(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("interval", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    LogError("%s: device %s has no interval", m_filename.c_str(), device->GetName().c_str());
    return false;
  }
  GetWord(line, strvalue);

  int interval;
  StrToInt(strvalue, interval);
  device->SetInterval(interval);

  return true;
}

void CConfig::SetDevicePrefix(CDeviceRS232* device, int devicenr)
{
  string line, strvalue;
  std::vector<uint8_t> prefix;
  int linenr = GetLineWithKey("prefix", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    return; //prefix is optional, so this is not an error 
  }

  while(GetWord(line, strvalue))
  {
    int iprefix;
    HexStrToInt(strvalue, iprefix);
    prefix.push_back(iprefix);
  }
  device->SetPrefix(prefix);
}

void CConfig::SetDevicePostfix(CDeviceRS232* device, int devicenr)
{
  string line, strvalue;
  std::vector<uint8_t> postfix;
  int linenr = GetLineWithKey("postfix", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    return; //postfix is optional, so this is not an error 
  }

  while(GetWord(line, strvalue))
  {
    int ipostfix;
    HexStrToInt(strvalue, ipostfix);
    postfix.push_back(ipostfix);
  }
  device->SetPostfix(postfix);
}

#ifdef HAVE_LIBPORTAUDIO
bool CConfig::SetDevicePeriod(CDeviceSound* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("period", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
  {
    LogError("%s: device %s has no period", m_filename.c_str(), device->GetName().c_str());
    return false;
  }
  GetWord(line, strvalue);

  int period;
  StrToInt(strvalue, period);
  device->SetPeriod(period);

  return true;
}

void CConfig::SetDeviceLatency(CDeviceSound* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("latency", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  double latency;
  StrToFloat(strvalue, latency);
  device->SetLatency(latency);
}
#endif

#ifdef HAVE_LIBUSB
void CConfig::SetDeviceBus(CDeviceUsb* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("bus", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  int busnr;
  StrToInt(strvalue, busnr);
  device->SetBusNumber(busnr);
}

void CConfig::SetDeviceAddress(CDeviceUsb* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("address", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  int address;
  StrToInt(strvalue, address);
  device->SetDeviceAddress(address);
}

void CConfig::SetSerial(CDeviceUsb* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("serial", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  device->SetSerial(strvalue);
}
#endif

void CConfig::SetDeviceAllowSync(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("allowsync", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  bool allowsync;
  StrToBool(strvalue, allowsync);
  device->SetAllowSync(allowsync);
}

void CConfig::SetDeviceDebug(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("debug", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  bool debug;
  StrToBool(strvalue, debug);
  device->SetDebug(debug);
}

bool CConfig::SetDeviceBits(CDeviceRS232* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("bits", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return false;

  GetWord(line, strvalue);

  int bits;
  StrToInt(strvalue, bits);
  device->SetMax((1 << (int64_t)bits) - 1);

  return true;
}

bool CConfig::SetDeviceMax(CDeviceRS232* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("max", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return false;

  GetWord(line, strvalue);

  int64_t max;
  StrToInt(strvalue, max);
  device->SetMax(max);

  return true;
}


void CConfig::SetDeviceDelayAfterOpen(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("delayafteropen", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  int delayafteropen;
  StrToInt(strvalue, delayafteropen);
  device->SetDelayAfterOpen(delayafteropen);
}

void CConfig::SetDeviceThreadPriority(CDevice* device, int devicenr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("threadpriority", m_devicelines[devicenr].lines, line);
  if (linenr == -1)
    return;

  GetWord(line, strvalue);

  int priority;
  StrToInt(strvalue, priority);
  device->SetThreadPriority(priority);
}

bool CConfig::SetLightName(CLight& light, std::vector<CConfigLine>& lines, int lightnr)
{
  string line, strvalue;
  int linenr = GetLineWithKey("name", lines, line);
  if (linenr == -1)
  {
    LogError("%s: light %i has no name", m_filename.c_str(), lightnr + 1);
    return false;
  }

  GetWord(line, strvalue);
  light.SetName(strvalue);
  return true;
}

void CConfig::SetLightScanRange(CLight& light, std::vector<CConfigLine>& lines)
{
  //hscan and vdscan are optional

  string line, strvalue;
  int linenr = GetLineWithKey("hscan", lines, line);
  if (linenr != -1)
  {
    float hscan[2];
    sscanf(line.c_str(), "%f %f", hscan, hscan + 1);
    light.SetHscan(hscan);
  }

  linenr = GetLineWithKey("vscan", lines, line);
  if (linenr != -1)
  {
    float vscan[2];
    sscanf(line.c_str(), "%f %f", vscan, vscan + 1);
    light.SetVscan(vscan);
  }
}  
