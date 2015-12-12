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

#ifndef CDEVICE
#define CDEVICE

#include "util/inclstdint.h"

//device types
#define NOTHING   0
#define MOMO      1
#define ATMO      2
#define POPEN     3
#define LTBL      4
#define SOUND     5
#define DIODER    6
#define KARATE    7
#define IBELIGHT  8
#define OLA       9
#define SEDU      10
#define LPD8806   11
#define WS2801    12
#define LIGHTPACK 13
#define AMBIODER  14


#include <string>
#include <vector>

//#include "client.h"
#include "util/thread.h"
#include "util/signaltimer.h"

class CClientsHandler; //forward declaration

class CChannel
{
  public:
    CChannel();
    void SetLight(int light)                 { m_light = light; }
    int  GetLight()                          { return m_light;  }

    void SetUsed(bool used)                  { m_isused = used; }
    bool IsUsed()                            { return m_isused; }
    
    void SetColor(int color)                 { m_color = color; }
    int  GetColor()                          { return m_color;  }
    
    void SetValue(float value)               { m_wantedvalue = value; }
    void SetFallback(float fallback)         { m_fallback = fallback; m_currentvalue = fallback; m_wantedvalue = fallback; }
    void SetValueToFallback()                { m_wantedvalue = m_fallback; }
    void SetSpeed(float speed)               { m_speed = speed; }
    void SetGamma(float gamma)               { m_gamma = gamma; }
    void SetAdjust(float adjust)             { m_adjust = adjust; }
    void SetBlacklevel(float blacklevel)     { m_blacklevel = blacklevel; }
    void SetSingleChange(float singlechange);

    float GetValue(int64_t time);

  private:
    int   m_color;          //color this channel is on, -1 means not used
    int   m_light;          //light this channel is on, -1 means not used

    bool  m_isused;         //whether a light uses this channel, set from clients handler
    
    float m_speed;          //speed of the light
    float m_wantedvalue;    //value the light wants to go to
    float m_fallback;       //value when no lights use this channel
    float m_gamma;
    float m_adjust;
    float m_blacklevel;
    float m_singlechange;

    float   m_currentvalue; //value we're currently at
    int64_t m_lastupdate;   //when m_currentvalue was last updated
};

class CDevice : public CThread
{
  public:
    CDevice(CClientsHandler& clients);
    
    void SetName(std::string name)                    { m_name = name; }
    void SetOutput(std::string output)                { m_output = output; }
    virtual void SetType(int type)                    { m_type = type; }
    void SetRate(int rate)                            { m_rate = rate; }
    void SetNrChannels(int nrchannels)                { m_channels.resize(nrchannels); }
    void SetChannel(CChannel& channel, int channelnr) { m_channels[channelnr] = channel; }
    void SetInterval(int64_t usecs)                   { m_interval = usecs; }
    void SetAllowSync(bool allowsync)                 { m_allowsync = allowsync; }
    void SetDebug(bool debug)                         { m_debug = debug; }
    void SetDelayAfterOpen(int64_t delay)             { m_delayafteropen = delay; }
    void SetThreadPriority(int priority)              { m_threadpriority = priority; m_setpriority = true;}

    int GetNrChannels()     { return m_channels.size(); }
      
    std::string GetName()   { return m_name; }
    std::string GetOutput() { return m_output; }

    virtual void Sync() {}; //wakes up the device, used to sync client input to device output

  protected:
    void Process();

    virtual bool SetupDevice() { return false; }
    virtual bool WriteOutput() { return false; }
    virtual void CloseDevice() { return; }

    std::string m_name;
    std::string m_output;
    int         m_type;
    int         m_rate;
    int64_t     m_interval;
    bool        m_allowsync;
    bool        m_debug;
    int64_t     m_delayafteropen;
    int         m_threadpriority;
    bool        m_setpriority;

    std::vector<CChannel> m_channels;

    CClientsHandler& m_clients;
};

#include "client.h"

#endif //CDEVICE
