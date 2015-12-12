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

#ifndef CCLIENT
#define CCLIENT

#include "util/inclstdint.h"

#include <vector>
#include <map>

#include "util/misc.h"
#include "util/mutex.h"
#include "util/thread.h"
#include "util/tcpsocket.h"
#include "util/messagequeue.h"

#include "light.h"
#include "device/device.h"

class CClient
{
  public:
    CClient();
    CTcpClientSocket m_socket;       //tcp socket for the client
    CMessageQueue    m_messagequeue; //stores client messages
    int              m_priority;     //priority of the client, 255 means an inactive client
    void             SetPriority(int priority) { m_priority = Clamp(priority, 0, 255); }
    int64_t          m_connecttime;  //when a client connected, used to decide which is the oldest client in case of same priority

    std::vector<CLight>        m_lights;    //lights of the client
    std::map<std::string, int> m_lightnrs;  //tree for light names to light nr conversion for faster searching

    void             InitLights(std::vector<CLight>& lights);
    int              LightNameToInt(std::string& lightname);
};

class CClientsHandler
{
  public:
    CClientsHandler(std::vector<CLight>& lights);
    void SetInterface(std::string address, int port) { m_address = address; m_port = port; }
    void FillChannels(std::vector<CChannel>& channels, int64_t time, CDevice* device); //called by devices
    void Process();
    void Cleanup();
    
  private:
    //where clients will connect to
    CTcpServerSocket m_socket;
    std::string      m_address;
    int              m_port;

    //clients we have, note that it's a vector of pointers so we can use a client outside a lock
    //and the pointer stays valid even if the vector changes
    std::vector<CClient*> m_clients;
    std::vector<CLight>&  m_lights;

    CMutex   m_mutex; //lock for the clients
    void     AddClient(CClient* client);
    void     GetReadableFd(std::vector<int>& sockets); //does select on all the sockets
    CClient* GetClientFromSock(int sock);     //gets a client from a socket fd
    void     RemoveClient(int sock);          //removes a client based on socket
    void     RemoveClient(CClient* client);   //removes a client based on pointer
    bool     HandleMessages(CClient* client); //handles client messages
    bool     ParseMessage(CClient* client, CMessage& message); //parses client messages
    bool     ParseGet(CClient* client, CMessage& message);
    bool     ParseSet(CClient* client, CMessage& message);
    bool     ParseSetLight(CClient* client, CMessage& message);
    bool     ParseSync(CClient* client);
    bool     SendVersion(CClient* client);    //this is used to check that boblightd and libboblight have the same protocol version
    bool     SendLights(CClient* client);     //sends light info, like name and area
    bool     SendPing(CClient* client);
};

#endif //CCLIENT
