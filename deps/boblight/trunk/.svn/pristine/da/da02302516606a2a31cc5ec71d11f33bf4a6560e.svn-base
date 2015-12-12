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

#include <iostream> //debug
#include <list>

#include <locale.h>

#include "config.h"

#include "client.h"
#include "util/lock.h"
#include "util/log.h"
#include "util/timeutils.h"
#include "protocolversion.h"

using namespace std;

extern volatile bool g_stop;

CClient::CClient()
{
  m_priority = 255;
  m_connecttime = -1;
}

void CClient::InitLights(std::vector<CLight>& lights)
{
  m_lights = lights;

  //generate a tree for fast lightname->lightnr conversion
  for (int i = 0; i < m_lights.size(); i++)
    m_lightnrs[m_lights[i].GetName()] = i;
}

int CClient::LightNameToInt(std::string& lightname)
{
  map<string, int>::iterator it = m_lightnrs.find(lightname);
  if (it == m_lightnrs.end())
    return -1;

  return it->second;
}

CClientsHandler::CClientsHandler(std::vector<CLight>& lights) : m_lights(lights)
{
}

//this is called from a loop from main()
void CClientsHandler::Process()
{
  //open listening socket if it's not already
  if (!m_socket.IsOpen())
  {
    Log("opening listening socket on %s:%i", m_address.empty() ? "*" : m_address.c_str(), m_port);
    if (!m_socket.Open(m_address, m_port, 1000000))
    {
      LogError("%s", m_socket.GetError().c_str());
      m_socket.Close();
    }
  }

  //see if there's a socket we can read from
  vector<int> sockets;
  GetReadableFd(sockets);

  for (vector<int>::iterator it = sockets.begin(); it != sockets.end(); it++)
  {
    int sock = *it;
    if (sock == m_socket.GetSock()) //we can read from the listening socket
    {
      CClient* client = new CClient;
      int returnv = m_socket.Accept(client->m_socket);
      if (returnv == SUCCESS)
      {
        Log("%s:%i connected", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
        AddClient(client);
      }
      else
      {
        delete client;
        Log("%s", m_socket.GetError().c_str());
      }
    }
    else
    {
      //get the client the sock fd belongs to
      CClient* client = GetClientFromSock(sock);
      if (client == NULL) //guess it belongs to nobody
        continue;

      //try to read data from the client
      CTcpData data;
      int returnv = client->m_socket.Read(data);
      if (returnv == FAIL)
      { //socket broke probably
        Log("%s", client->m_socket.GetError().c_str());
        RemoveClient(client);
        continue;
      }

      //add data to the messagequeue
      client->m_messagequeue.AddData(data.GetData(), data.GetSize());

      //check messages from the messaqueue and parse them, if it fails remove the client
      if (!HandleMessages(client))
        RemoveClient(client);
    }
  }
}

void CClientsHandler::Cleanup()
{
  //kick off all clients
  Log("disconnecting clients");
  CLock lock(m_mutex);
  while(m_clients.size())
  {
    RemoveClient(m_clients.front());
  }    
  lock.Leave();

  Log("closing listening socket");
  m_socket.Close();

  Log("clients handler stopped");
}

//called by the connection handler
void CClientsHandler::AddClient(CClient* client)
{
  CLock lock(m_mutex);

  if (m_clients.size() >= FD_SETSIZE) //maximum number of clients reached
  {
    LogError("number of clients reached maximum %i", FD_SETSIZE);
    CTcpData data;
    data.SetData("full\n");
    client->m_socket.Write(data);
    delete client;
    return;
  }

  //assign lights and put the pointer in the clients vector
  client->InitLights(m_lights);
  m_clients.push_back(client);
}

#define WAITTIME 10000000
//does select on all the client sockets, with a timeout of 10 seconds
void CClientsHandler::GetReadableFd(vector<int>& sockets)
{
  CLock lock(m_mutex);

  //no clients so we just sleep
  if (m_clients.size() == 0 && !m_socket.IsOpen()) 
  {
    lock.Leave();
    USleep(WAITTIME, &g_stop);
    return;
  }

  //store all the client sockets
  vector<int> waitsockets;
  waitsockets.push_back(m_socket.GetSock());
  for (int i = 0; i < m_clients.size(); i++)
    waitsockets.push_back(m_clients[i]->m_socket.GetSock());

  lock.Leave();
  
  int    highestsock = -1;
  fd_set rsocks;

  FD_ZERO(&rsocks);
  for (int i = 0; i < waitsockets.size(); i++)
  {
    FD_SET(waitsockets[i], &rsocks);
    if (waitsockets[i] > highestsock)
      highestsock = waitsockets[i];
  }

  struct timeval tv;
  tv.tv_sec = WAITTIME / 1000000;
  tv.tv_usec = (WAITTIME % 1000000);

  int returnv = select(highestsock + 1, &rsocks, NULL, NULL, &tv);

  if (returnv == 0) //select timed out
  {
    return;
  }
  else if (returnv == -1) //select had an error
  {
    Log("select() %s", GetErrno().c_str());
    return;
  }

  //return all sockets that can be read
  for (int i = 0; i < waitsockets.size(); i++)
  {
    if (FD_ISSET(waitsockets[i], &rsocks))
      sockets.push_back(waitsockets[i]);
  }
}

//gets a client from a socket fd
CClient* CClientsHandler::GetClientFromSock(int sock)
{
  CLock lock(m_mutex);
  for (int i = 0; i < m_clients.size(); i++)
  {
    if (m_clients[i]->m_socket.GetSock() == sock)
      return m_clients[i];
  }
  return NULL;
}

//removes a client based on socket
void CClientsHandler::RemoveClient(int sock)
{
  CLock lock(m_mutex);
  for (int i = 0; i < m_clients.size(); i++)
  {
    if (m_clients[i]->m_socket.GetSock() == sock)
    {
      Log("removing %s:%i", m_clients[i]->m_socket.GetAddress().c_str(), m_clients[i]->m_socket.GetPort());
      delete m_clients[i];
      m_clients.erase(m_clients.begin() + i);
      return;
    }
  }
}

//removes a client based on pointer
void CClientsHandler::RemoveClient(CClient* client)
{
  CLock lock(m_mutex);
  for (int i = 0; i < m_clients.size(); i++)
  {
    if (m_clients[i] == client)
    {
      Log("removing %s:%i", m_clients[i]->m_socket.GetAddress().c_str(), m_clients[i]->m_socket.GetPort());
      delete m_clients[i];
      m_clients.erase(m_clients.begin() + i);
      return;
    }
  }
}

//handles client messages
bool CClientsHandler::HandleMessages(CClient* client)
{
  if (client->m_messagequeue.GetRemainingDataSize() > MAXDATA) //client sent too much data
  {
    LogError("%s:%i sent too much data", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }
  
  //loop until there are no more messages
  while (client->m_messagequeue.GetNrMessages() > 0)
  {
    CMessage message = client->m_messagequeue.GetMessage();
    if (!ParseMessage(client, message))
      return false;
  }
  return true;
}

//parses client messages
bool CClientsHandler::ParseMessage(CClient* client, CMessage& message)
{
  CTcpData data;
  string messagekey;
  //an empty message is invalid
  if (!GetWord(message.message, messagekey))
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }

  if (messagekey == "hello")
  {
    Log("%s:%i said hello", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    data.SetData("hello\n");
    if (client->m_socket.Write(data) != SUCCESS)
    {
      Log("%s", client->m_socket.GetError().c_str());
      return false;
    }
    CLock lock(m_mutex);
    if (client->m_connecttime == -1)
      client->m_connecttime = message.time;
  }
  else if (messagekey == "ping")
  {
    return SendPing(client);
  }
  else if (messagekey == "get")
  {
    return ParseGet(client, message);
  }
  else if (messagekey == "set")
  {
    return ParseSet(client, message);
  }
  else if (messagekey == "sync")
  {
    return ParseSync(client);
  }
  else
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }

  return true;
}

bool CClientsHandler::ParseGet(CClient* client, CMessage& message)
{
  CTcpData data;
  string messagekey;
  if (!GetWord(message.message, messagekey))
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }

  if (messagekey == "version")
  {
    return SendVersion(client);
  }
  else if (messagekey == "lights")
  {
    return SendLights(client);
  }
  else
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }
}

//this is used to check that boblightd and libboblight have the same protocol version
//the check happens in libboblight
bool CClientsHandler::SendVersion(CClient* client)
{
  CTcpData data;

  data.SetData("version " + static_cast<string>(PROTOCOLVERSION) + "\n");

  if (client->m_socket.Write(data) != SUCCESS)
  {
    Log("%s", client->m_socket.GetError().c_str());
    return false;
  }
  return true;
}

//sends light info, like name and area
bool CClientsHandler::SendLights(CClient* client)
{
  CTcpData data;

  //build up messages by appending to CTcpData
  data.SetData("lights " + ToString(client->m_lights.size()) + "\n");

  for (int i = 0; i < client->m_lights.size(); i++)
  {
    data.SetData("light " + client->m_lights[i].GetName() + " ", true);
    
    data.SetData("scan ", true);
    data.SetData(ToString(client->m_lights[i].GetVscan()[0]) + " ", true);
    data.SetData(ToString(client->m_lights[i].GetVscan()[1]) + " ", true);
    data.SetData(ToString(client->m_lights[i].GetHscan()[0]) + " ", true);
    data.SetData(ToString(client->m_lights[i].GetHscan()[1]), true);
    data.SetData("\n", true);
  }

  if (client->m_socket.Write(data) != SUCCESS)
  {
    Log("%s", client->m_socket.GetError().c_str());
    return false;
  }
  return true;
}

bool CClientsHandler::SendPing(CClient* client)
{
  CLock lock(m_mutex);

  //check if any light is used
  int lightsused = 0;
  for (unsigned int i = 0; i < client->m_lights.size(); i++)
  {
    if (client->m_lights[i].GetNrUsers() > 0)
    {
      lightsused = 1;
      break; //if one light is used we have enough info
    }
  }

  lock.Leave();

  CTcpData data;
  data.SetData("ping " + ToString(lightsused) + "\n");

  if (client->m_socket.Write(data) != SUCCESS)
  {
    Log("%s", client->m_socket.GetError().c_str());
    return false;
  }
  return true;
}

bool CClientsHandler::ParseSet(CClient* client, CMessage& message)
{
  CTcpData data;
  string messagekey;
  if (!GetWord(message.message, messagekey))
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }

  if (messagekey == "priority")
  {
    int priority;
    string strpriority;
    if (!GetWord(message.message, strpriority) || !StrToInt(strpriority, priority))
    {
      LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
      return false;
    }
    CLock lock(m_mutex);
    client->SetPriority(priority);
    lock.Leave();
    Log("%s:%i priority set to %i", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort(), client->m_priority);
  }
  else if (messagekey == "light")
  {
    return ParseSetLight(client, message);
  }    
  else
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }
  return true;
}

bool CClientsHandler::ParseSetLight(CClient* client, CMessage& message)
{
  string lightname;
  string lightkey;
  int lightnr;

  if (!GetWord(message.message, lightname) || !GetWord(message.message, lightkey) || (lightnr = client->LightNameToInt(lightname)) == -1)
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }

  if (lightkey == "rgb")
  {
    float rgb[3];
    string value;

    ConvertFloatLocale(message.message); //workaround for locale mismatch (, and .)
    
    for (int i = 0; i < 3; i++)
    {
      if (!GetWord(message.message, value) || !StrToFloat(value, rgb[i]))
      {
        LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
        return false;
      }
    }

    CLock lock(m_mutex);
    client->m_lights[lightnr].SetRgb(rgb, message.time);
  }
  else if (lightkey == "speed")
  {
    float speed;
    string value;

    ConvertFloatLocale(message.message); //workaround for locale mismatch (, and .)

    if (!GetWord(message.message, value) || !StrToFloat(value, speed))
    {
      LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
      return false;
    }

    CLock lock(m_mutex);
    client->m_lights[lightnr].SetSpeed(speed);
  }
  else if (lightkey == "interpolation")
  {
    bool interpolation;
    string value;

    if (!GetWord(message.message, value) || !StrToBool(value, interpolation))
    {
      LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
      return false;
    }

    CLock lock(m_mutex);
    client->m_lights[lightnr].SetInterpolation(interpolation);
  }
  else if (lightkey == "use")
  {
    bool use;
    string value;

    if (!GetWord(message.message, value) || !StrToBool(value, use))
    {
      LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
      return false;
    }

    CLock lock(m_mutex);
    client->m_lights[lightnr].SetUse(use);
  }
  else if (lightkey == "singlechange")
  {
    float singlechange;
    string value;

    ConvertFloatLocale(message.message); //workaround for locale mismatch (, and .)

    if (!GetWord(message.message, value) || !StrToFloat(value, singlechange))
    {
      LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
      return false;
    }

    CLock lock(m_mutex);
    client->m_lights[lightnr].SetSingleChange(singlechange);
  }
  else
  {
    LogError("%s:%i sent gibberish", client->m_socket.GetAddress().c_str(), client->m_socket.GetPort());
    return false;
  }

  return true;
}

//wakes up all devices that use this client, so the client input and the device output is synchronized
bool CClientsHandler::ParseSync(CClient* client)
{
  CLock lock(m_mutex);

  list<CDevice*> users;

  //build up a list of devices using this client's input
  for (unsigned int i = 0; i < client->m_lights.size(); i++)
  {
    for (unsigned int j = 0; j < client->m_lights[i].GetNrUsers(); j++)
      users.push_back(client->m_lights[i].GetUser(j));
  }

  lock.Leave();

  //remove duplicates
  users.sort();
  users.unique();

  //message all devices
  for (list<CDevice*>::iterator it = users.begin(); it != users.end(); it++)
    (*it)->Sync();

  return true;
}

//called by devices
void CClientsHandler::FillChannels(std::vector<CChannel>& channels, int64_t time, CDevice* device)
{
  list<CLight*>  usedlights;

  CLock lock(m_mutex);

  //get the oldest client with the highest priority
  for (int i = 0; i < channels.size(); i++)
  {
    int64_t clienttime = 0x7fffffffffffffffLL;
    int     priority   = 255;
    int     light = channels[i].GetLight();
    int     color = channels[i].GetColor();
    int     clientnr = -1;

    if (light == -1 || color == -1) //unused channel
      continue;

    for (int j = 0; j < m_clients.size(); j++)
    {
      if (m_clients[j]->m_priority == 255 || m_clients[j]->m_connecttime == -1 || !m_clients[j]->m_lights[light].GetUse())
        continue; //this client we don't use

      //this client has a high priority (lower number) than the current one, or has the same and is older
      if (m_clients[j]->m_priority < priority || (priority == m_clients[j]->m_priority && m_clients[j]->m_connecttime < clienttime))
      {
        clientnr = j;
        clienttime = m_clients[j]->m_connecttime;
        priority = m_clients[j]->m_priority;
      }
    }

    if (clientnr == -1) //no client for the light on this channel
    {
      channels[i].SetUsed(false);
      channels[i].SetSpeed(m_lights[light].GetSpeed());
      channels[i].SetValueToFallback();
      channels[i].SetGamma(1.0);
      channels[i].SetAdjust(1.0);
      channels[i].SetBlacklevel(0.0);
      continue;
    }

    //fill channel with values from the client
    channels[i].SetUsed(true);
    channels[i].SetValue(m_clients[clientnr]->m_lights[light].GetColorValue(color, time));
    channels[i].SetSpeed(m_clients[clientnr]->m_lights[light].GetSpeed());
    channels[i].SetGamma(m_clients[clientnr]->m_lights[light].GetGamma(color));
    channels[i].SetAdjust(m_clients[clientnr]->m_lights[light].GetAdjust(color));
    channels[i].SetBlacklevel(m_clients[clientnr]->m_lights[light].GetBlacklevel(color));
    channels[i].SetSingleChange(m_clients[clientnr]->m_lights[light].GetSingleChange(device));

    //save pointer to this light because we have to reset the singlechange later
    //more than one channel can use a light so can't do this from the loop
    usedlights.push_back(&m_clients[clientnr]->m_lights[light]);
  }

  //remove duplicate lights
  usedlights.sort();
  usedlights.unique();

  //reset singlechange
  for (list<CLight*>::iterator it = usedlights.begin(); it != usedlights.end(); it++)
    (*it)->ResetSingleChange(device);

  //update which lights we're using
  for (int i = 0; i < m_clients.size(); i++)
  {
    for (int j = 0; j < m_clients[i]->m_lights.size(); j++)
    {
      bool lightused = false;
      for (list<CLight*>::iterator it = usedlights.begin(); it != usedlights.end(); it++)
      {
        if (*it == &m_clients[i]->m_lights[j])
        {
          lightused = true;
          break;
        }
      }

      if (lightused)
        m_clients[i]->m_lights[j].AddUser(device);
      else
        m_clients[i]->m_lights[j].ClearUser(device);
    }
  }
}

