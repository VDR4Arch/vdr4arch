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

#include <string>
#include <iostream> //debug
#include <sstream>

#include "boblight_client.h"
#include "util/misc.h"
#include "util/timeutils.h"
#include "protocolversion.h"

using namespace std;
using namespace boblight;

#define GAMMASIZE (sizeof(m_gammacurve) / sizeof(m_gammacurve[0]))

CLight::CLight()
{
  #define BOBLIGHT_OPTION(name, type, min, max, default, variable, postprocess) variable = default;
  #include "options.h"
  #undef  BOBLIGHT_OPTION

  m_singlechange = 0.0;

  m_width = -1;
  m_height = -1;

  memset(m_rgb, 0, sizeof(m_rgb));
  m_rgbcount = 0;
  memset(m_prevrgb, 0, sizeof(m_prevrgb));
  memset(m_hscanscaled, 0, sizeof(m_hscanscaled));
  memset(m_vscanscaled, 0, sizeof(m_vscanscaled));

  for (int i = 0; i < GAMMASIZE; i++)
    m_gammacurve[i] = i;
}

string CLight::SetOption(const char* option, bool& send)
{
  string stroption = option;
  string strname;

  send = false;
  
  if (!GetWord(stroption, strname))
    return "emtpy option"; //string with only whitespace

  #define BOBLIGHT_OPTION(name, type, min, max, default, variable, postprocess) \
  if (strname == #name) \
  { \
    type value; \
    if (#type == "bool")\
    {\
      if (!StrToBool(stroption, *(bool*)(&value)))\
        return "invalid value " + stroption + " for option " + strname + " with type " + #type; \
    }\
    else\
    {\
      stringstream stream; \
      stream << stroption; \
      stream >> value; \
      if (stream.fail()) return "invalid value " + stroption + " for option " + strname + " with type " + #type; \
      \
    }\
    variable = value; \
    postprocess\
    \
    return ""; \
  }
  #include "options.h"
  #undef BOBLIGHT_OPTION

  return "unknown option " + strname;
}

std::string CLight::GetOption(const char* option, std::string& output)
{
  string stroption = option;
  string strname;

  if (!GetWord(stroption, strname))
    return "emtpy option"; //string with only whitespace

  #define BOBLIGHT_OPTION(name, type, min, max, default, variable, postprocess) \
  if (#name == strname)\
  {\
    output = ToString(variable);\
    return "";\
  }
  #include "options.h"
  #undef BOBLIGHT_OPTION

  return "unknown option";
}

void CLight::AddPixel(int* rgb)
{
  if (rgb[0] >= m_threshold || rgb[1] >= m_threshold || rgb[2] >= m_threshold)
  {
    if (m_gamma == 1.0)
    {
      m_rgb[0] += Clamp(rgb[0], 0, 255);
      m_rgb[1] += Clamp(rgb[1], 0, 255);
      m_rgb[2] += Clamp(rgb[2], 0, 255);
    }
    else
    {
      m_rgb[0] += m_gammacurve[Clamp(rgb[0], 0, GAMMASIZE - 1)];
      m_rgb[1] += m_gammacurve[Clamp(rgb[1], 0, GAMMASIZE - 1)];
      m_rgb[2] += m_gammacurve[Clamp(rgb[2], 0, GAMMASIZE - 1)];
    }
  }
  m_rgbcount++;
}

void CLight::GetRGB(float* rgb)
{
  //if no pixels are set, the denominator is 0, so just return black
  if (m_rgbcount == 0)
  {
    for (int i = 0; i < 3; i++)
    {
      rgb[i] = 0.0f;
      m_rgb[i] = 0.0f;
    }

    return;
  }
  
  //convert from numerator/denominator to float
  for (int i = 0; i < 3; i++)
  {
    rgb[i] = Clamp(m_rgb[i] / (float)m_rgbcount / 255.0f, 0.0f, 1.0f);
    m_rgb[i] = 0.0f;
  }
  m_rgbcount = 0;

  //this tries to set the speed based on how fast the input is changing
  //it needs sync mode to work properly
  if (m_autospeed > 0.0)
  {
    float change = Abs(rgb[0] - m_prevrgb[0]) + Abs(rgb[1] - m_prevrgb[1]) + Abs(rgb[2] - m_prevrgb[2]);
    change /= 3.0;

    //only apply singlechange if it's large enough, otherwise we risk sending it continously
    if (change > 0.001)
      m_singlechange = Clamp(change * m_autospeed / 10.0, 0.0, 1.0);
    else
      m_singlechange = 0.0;
  }

  memcpy(m_prevrgb, rgb, sizeof(m_prevrgb));

  //we need some hsv adjustments
  if (m_value != 1.0 || m_valuerange[0] != 0.0 || m_valuerange[1] != 1.0 ||
      m_saturation != 1.0  || m_satrange[0] != 0.0 || m_satrange[1] != 1.0)
  {
    //rgb - hsv conversion, thanks wikipedia!
    float hsv[3];
    float max = Max(rgb[0], rgb[1], rgb[2]);
    float min = Min(rgb[0], rgb[1], rgb[2]);

    if (min == max) //grayscale
    {
      hsv[0] = -1.0f; //undefined
      hsv[1] = 0.0; //no saturation
      hsv[2] = min; //value
    }
    else
    {
      if (max == rgb[0]) //red zone
      {
        hsv[0] = (60.0f * ((rgb[1] - rgb[2]) / (max - min)) + 360.0f);
        while (hsv[0] >= 360.0f)
          hsv[0] -= 360.0f;
      }
      else if (max == rgb[1]) //green zone
      {
        hsv[0] = 60.0f * ((rgb[2] - rgb[0]) / (max - min)) + 120.0f;
      }
      else if (max == rgb[2]) //blue zone
      {
        hsv[0] = 60.0f * ((rgb[0] - rgb[1]) / (max - min)) + 240.0f;
      }
      
      hsv[1] = (max - min) / max; //saturation
      hsv[2] = max; //value
    }

    //saturation and value adjustment
    hsv[1] = Clamp(hsv[1] * m_saturation, m_satrange[0],   m_satrange[1]);
    hsv[2] = Clamp(hsv[2] * m_value,      m_valuerange[0], m_valuerange[1]);

    if (hsv[0] == -1.0f) //grayscale
    {
      for (int i = 0; i < 3; i++)
        rgb[i] = hsv[2];
    }
    else
    {
      int hi = (int)(hsv[0] / 60.0f) % 6;
      float f = (hsv[0] / 60.0f) - (float)(int)(hsv[0] / 60.0f);

      float s = hsv[1];
      float v = hsv[2];
      float p = v * (1.0f - s);
      float q = v * (1.0f - f * s);
      float t = v * (1.0f - (1.0f - f) * s);

      if (hi == 0)
      { rgb[0] = v; rgb[1] = t; rgb[2] = p; }
      else if (hi == 1)
      { rgb[0] = q; rgb[1] = v; rgb[2] = p; }
      else if (hi == 2)
      { rgb[0] = p; rgb[1] = v; rgb[2] = t; }
      else if (hi == 3)
      { rgb[0] = p; rgb[1] = q; rgb[2] = v; }
      else if (hi == 4)
      { rgb[0] = t; rgb[1] = p; rgb[2] = v; }
      else if (hi == 5)
      { rgb[0] = v; rgb[1] = p; rgb[2] = q; }               
    }

    for (int i = 0; i < 3; i++)
      rgb[i] = Clamp(rgb[i], 0.0f, 1.0f);
  }
}

//scale the light's scanrange to the dimensions set with boblight_setscanrange()
void CLight::SetScanRange(int width, int height)
{
    m_width = width;
    m_height = height;

    m_hscanscaled[0] = Round32(m_hscan[0] / 100.0 * ((float)width  - 1));
    m_hscanscaled[1] = Round32(m_hscan[1] / 100.0 * ((float)width  - 1));
    m_vscanscaled[0] = Round32(m_vscan[0] / 100.0 * ((float)height - 1));
    m_vscanscaled[1] = Round32(m_vscan[1] / 100.0 * ((float)height - 1));
}

int CBoblight::Connect(const char* address, int port, int usectimeout)
{
  CMessage message;
  CTcpData data;
  int64_t  now;
  int64_t  target;
  string   word;

  //set address
  m_usectimeout = usectimeout;
  if (address)
    m_address = address;
  else
    m_address = "127.0.0.1";

  //set port
  if (port >= 0)
    m_port = port;
  else
    m_port = 19333;

  //try to open a tcp connection
  if (m_socket.Open(m_address, m_port, m_usectimeout) != SUCCESS)
  {
    m_error = m_socket.GetError();
    return 0;
  }

  //write hello to the server, we should get hello back
  if (!WriteDataToSocket("hello\n"))
    return 0;

  if (!ReadDataToQueue())
    return 0;

  message = m_messagequeue.GetMessage();
  if (!ParseWord(message, "hello"))
  {
    m_error = m_address + ":" + ToString(m_port) + " sent gibberish";
    return 0;
  }

  //get the protocol version from the server
  if (!WriteDataToSocket("get version\n"))
    return 0;

  if (!ReadDataToQueue())
    return 0;

  message = m_messagequeue.GetMessage();
  
  if (!ParseWord(message, "version") || !GetWord(message.message, word))
  {
    m_error = m_address + ":" + ToString(m_port) + " sent gibberish";
    return 0;
  }

  //if we don't get the same protocol version back as we have, we can't work together
  if (word != PROTOCOLVERSION)
  {
    m_error = "version mismatch, " + m_address + ":" + ToString(m_port) + " has version \"" + word +
              "\", libboblight has version \"" + PROTOCOLVERSION + "\"";
    return 0;
  }

  //get lights info, like number, names and area
  if (!WriteDataToSocket("get lights\n"))
    return 0;

  if (!ReadDataToQueue())
    return 0;

  message = m_messagequeue.GetMessage();
  if (!ParseLights(message))
  {
    m_error = m_address + ":" + ToString(m_port) + " sent gibberish";
    return 0;
  }
  
  return 1;
}

CBoblight::CBoblight()
{
  int padsize = 1;
  //get option name pad size so it looks pretty
  #define BOBLIGHT_OPTION(name, type, min, max, default, variable, postprocess) \
  if (strlen(#name) + 1 > padsize)\
    padsize = strlen(#name) + 1;
  #include "options.h"
  #undef BOBLIGHT_OPTION

  //stick in a line that describes the options
  string option = "name";
  option.append(Max(padsize - option.length(), 1), ' ');
  option += "type    min     max     default";
  m_options.push_back(option);

  //fill vector with option strings
  #define BOBLIGHT_OPTION(name, type, min, max, default, variable, postprocess) \
  {\
    string option = #name;\
    option.append(padsize - strlen(#name), ' ');\
    \
    option += #type;\
    option.append(Max(8 - strlen(#type), 1), ' ');\
    \
    option += #min;\
    option.append(Max(8 - strlen(#min), 1), ' ');\
    \
    option += #max;\
    option.append(Max(8 - strlen(#max), 1), ' ');\
    \
    if (strcmp(#default, "-1.0") == 0)\
      option += "set by boblightd";\
    else\
      option += #default;\
    \
    m_options.push_back(option);\
  }
  #include "options.h"
  #undef BOBLIGHT_OPTION
}

//reads from socket until timeout or one message has arrived
bool CBoblight::ReadDataToQueue()
{
  CTcpData data;
  int64_t  now = GetTimeUs();
  int64_t  target = now + m_usectimeout; 
  int      nrmessages = m_messagequeue.GetNrMessages();

  while (now < target && m_messagequeue.GetNrMessages() == nrmessages)
  {
    if (m_socket.Read(data) != SUCCESS)
    {
      m_error = m_socket.GetError();
      return false;
    }

    m_messagequeue.AddData(data.GetData());

    if (m_messagequeue.GetRemainingDataSize() > MAXDATA)
    {
      m_error = m_address + ":" + ToString(m_port) + " sent too much data";
      return false;
    }

    now = GetTimeUs();
  }

  if (nrmessages == m_messagequeue.GetNrMessages())
  {
    m_error = m_address + ":" + ToString(m_port) + " read timed out";
    return false;
  }
  return true;
}

bool CBoblight::WriteDataToSocket(std::string strdata)
{
  CTcpData data;
  data.SetData(strdata);

  if (m_socket.Write(data) != SUCCESS)
  {
    m_error = m_socket.GetError();
    return false;
  }
  
  return true;
}

//removes one word from the string in the messages, and compares it to wordtocmp
bool CBoblight::ParseWord(CMessage& message, std::string wordtocmp)
{
  string readword;
  if (!GetWord(message.message, readword) || readword != wordtocmp)
    return false;

  return true;
}

bool CBoblight::ParseLights(CMessage& message)
{
  string word;
  int nrlights;

  //first word in the message is "lights", second word is the number of lights
  if (!ParseWord(message, "lights") || !GetWord(message.message, word) || !StrToInt(word, nrlights) || nrlights < 1)
    return false;

  for (int i = 0; i < nrlights; i++)
  {
    CLight light;

    //read some data to the message queue if we have no messages
    if (m_messagequeue.GetNrMessages() == 0)
    {
      if (!ReadDataToQueue())
        return false;
    }

    message = m_messagequeue.GetMessage();

    //first word sent is "light, second one is the name
    if (!ParseWord(message, "light") || !GetWord(message.message, light.m_name))
    {
      return false;
    }

    //third one is "scan"
    if (!ParseWord(message, "scan"))
      return false;

    //now we read the scanrange
    string scanarea;
    for (int i = 0; i < 4; i++)
    {
      if (!GetWord(message.message, word))
        return false;

      scanarea += word + " ";
    }

    ConvertFloatLocale(scanarea); //workaround for locale mismatch (, and .)

    if (sscanf(scanarea.c_str(), "%f %f %f %f", light.m_vscan, light.m_vscan + 1, light.m_hscan, light.m_hscan + 1) != 4)
      return false;    

    m_lights.push_back(light);
  }    
  return true;
}

const char* CBoblight::GetLightName(int lightnr)
{
  if (lightnr < 0) //negative lights don't exist, so we set it to an invalid number to get the error message
    lightnr = m_lights.size();

  if (CheckLightExists(lightnr))
    return m_lights[lightnr].m_name.c_str();

  return NULL;
}

int CBoblight::SetPriority(int priority)
{
  string data = "set priority " + ToString(priority) + "\n";

  return WriteDataToSocket(data);
}

bool CBoblight::CheckLightExists(int lightnr, bool printerror /*= true*/)
{
  if (lightnr >= (int)m_lights.size())
  {
    if (printerror)
    {
      m_error = "light " + ToString(lightnr) + " doesn't exist (have " + ToString(m_lights.size()) + " lights)";
    }
    return false;
  }
  return true;
}

void CBoblight::SetScanRange(int width, int height)
{
  for (int i = 0; i < m_lights.size(); i++)
  {
    m_lights[i].SetScanRange(width, height);
  }
}

int CBoblight::AddPixel(int lightnr, int* rgb)
{
  if (!CheckLightExists(lightnr))
    return 0;

  if (lightnr < 0)
  {
    for (int i = 0; i < m_lights.size(); i++)
      m_lights[i].AddPixel(rgb);
  }
  else
  {
    m_lights[lightnr].AddPixel(rgb);
  }

  return 1;
}

void CBoblight::AddPixel(int* rgb, int x, int y)
{
  for (int i = 0; i < m_lights.size(); i++)
  {
    if (x >= m_lights[i].m_hscanscaled[0] && x <= m_lights[i].m_hscanscaled[1] &&
        y >= m_lights[i].m_vscanscaled[0] && y <= m_lights[i].m_vscanscaled[1])
    {
      m_lights[i].AddPixel(rgb);
    }
  }
}

int CBoblight::SendRGB(int sync, int* outputused)
{
  string data;

  for (int i = 0; i < m_lights.size(); i++)
  {
    float rgb[3];
    m_lights[i].GetRGB(rgb);
    data += "set light " + m_lights[i].m_name + " rgb " + ToString(rgb[0]) + " " + ToString(rgb[1]) + " " + ToString(rgb[2]) + "\n";
    if (m_lights[i].m_autospeed > 0.0 && m_lights[i].m_singlechange > 0.0)
      data += "set light " + m_lights[i].m_name + " singlechange " + ToString(m_lights[i].m_singlechange) + "\n";
  }

  //send a message that we want devices to sync to our input
  if (sync)
    data += "sync\n";

  //if we want to check if our output is used, send a ping message
  if (outputused)
    data += "ping\n";

  if (!WriteDataToSocket(data))
    return 0;

  if (outputused)
    return Ping(outputused, false);
  else
    return 1;
}

int CBoblight::Ping(int* outputused, bool send)
{
  string word;
  
  if (send)
  {
    if (!WriteDataToSocket("ping\n"))
      return 0;
  }

  if (!ReadDataToQueue())
    return 0;

  CMessage message = m_messagequeue.GetMessage();

  if (!GetWord(message.message, word) || word != "ping")
  {
    m_error = m_address + ":" + ToString(m_port) + " sent gibberish";
    return 0;
  }

  //client can set outputused to NULL
  if (outputused)
  {
    if (!GetWord(message.message, word) || !StrToInt(word, *outputused))
    {
      m_error = m_address + ":" + ToString(m_port) + " sent gibberish";
      return 0;
    }
  }

  return 1;
}

int CBoblight::GetNrOptions()
{
  return m_options.size();
}

const char* CBoblight::GetOptionDescription(int option)
{
  if (option < 0 || option >= m_options.size())
    return NULL;

  return m_options[option].c_str();
}

int CBoblight::SetOption(int lightnr, const char* option)
{
  string error;
  string data;
  bool   send;
  
  if (!CheckLightExists(lightnr))
    return 0;

  if (lightnr < 0)
  {
    for (int i = 0; i < m_lights.size(); i++)
    {
      error = m_lights[i].SetOption(option, send);
      if (!error.empty())
      {
        m_error = error;
        return 0;
      }
      if (send)
      {
        data += "set light " + m_lights[i].m_name + " " + option + "\n";
      }
    }
  }
  else
  {
    error = m_lights[lightnr].SetOption(option, send);
    if (!error.empty())
    {
      m_error = error;
      return 0;
    }
    if (send)
    {
      data += "set light " + m_lights[lightnr].m_name + " " + option + "\n";
    }
  }

  if (!WriteDataToSocket(data))
    return 0;

  return 1;
}

int CBoblight::GetOption(int lightnr, const char* option, const char** output)
{
  if (lightnr < 0) //negative lights don't exist, so we set it to an invalid number to get the error message
    lightnr = m_lights.size();

  if (!CheckLightExists(lightnr))
    return 0;

  string error = m_lights[lightnr].GetOption(option, m_lastoption);
  if (!error.empty())
  {
    m_error = error;
    return 0;
  }

  *output = m_lastoption.c_str();
  
  return 1;
}
