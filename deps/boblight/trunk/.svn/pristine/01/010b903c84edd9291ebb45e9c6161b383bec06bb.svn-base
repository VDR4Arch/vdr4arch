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

#include "util/log.h"
#include "util/misc.h"
#include "util/mutex.h"
#include "util/lock.h"
#include "util/misc.h"
#include "devicesound.h"
#include "util/timeutils.h"

using namespace std;

//we can init portaudio from multiple threads, so it needs a lock
class CPortAudioInit
{
  public:
    int Init()
    {
      CLock lock(m_mutex);
      return Pa_Initialize();
    }

    int DeInit()
    {
      CLock lock(m_mutex);
      return Pa_Terminate();
    }

  private:
    CMutex m_mutex;
}
g_portaudioinit;

CDeviceSound::CDeviceSound(CClientsHandler& clients) : CDevice(clients)
{
  m_opened = false;
  m_initialized = false;
  m_started = false;
  m_callbacksignal = false;
  m_latency = -1;
}

bool CDeviceSound::SetupDevice()
{
  //init portaudio
  int err = g_portaudioinit.Init();
  if (err != paNoError)
  {
    LogError("%s: %s", m_name.c_str(), Pa_GetErrorText(err));
    return false;
  }
  m_initialized = true;

  //get nr of devices
  int nrdevices = Pa_GetDeviceCount();
  if (nrdevices < 0)
  {
    LogError("%s: %s", m_name.c_str(), Pa_GetErrorText(nrdevices));
    return false;
  }
  else if (nrdevices == 0)
  {
    LogError("%s: no portaudio devices found", m_name.c_str());
    return false;
  }

  //print info from portaudio to the log
  Log("%s: found %i portaudio devices", m_name.c_str(), nrdevices);
  const PaDeviceInfo *deviceinfo;
  const PaHostApiInfo* hostapiinfo;
  for (int i = 0; i < nrdevices; i++)
  {
    deviceinfo = Pa_GetDeviceInfo(i);
    if (deviceinfo->maxOutputChannels)
    {
      hostapiinfo = Pa_GetHostApiInfo(deviceinfo->hostApi);
      Log("n:%2i channels:%3i \"%s:%s\"", i, deviceinfo->maxOutputChannels, hostapiinfo->name, deviceinfo->name);
    }
  }

  //split api and name from api:name
  //m_output is already checked for being in that format in CConfig
  string api  = m_output.substr(0, m_output.find(':'));
  string name = m_output.substr(api.size() + 1);

  //get a device which name matches m_output
  int devicenr = -1;
  for (int i = 0; i < nrdevices; i++)
  {
    deviceinfo  = Pa_GetDeviceInfo(i);
    hostapiinfo = Pa_GetHostApiInfo(deviceinfo->hostApi);
    if (api == hostapiinfo->name && name == deviceinfo->name)
    {
      devicenr = i;
      break;
    }
  }
  
  if (devicenr == -1)
  {
    LogError("%s: \"%s\" not found", m_name.c_str(), m_output.c_str());
    return false;
  }
  else if (deviceinfo->maxOutputChannels < m_channels.size())
  {
    LogError("%s: \"%s\" doesn't have enough channels", m_name.c_str(), m_output.c_str());
    return false;
  }
  else
  {
    Log("%s using \"%s\"", m_name.c_str(), m_output.c_str());
  }

  //set up portaudio the way we want it
  PaStreamParameters outputparameters = {};
  outputparameters.channelCount       = m_channels.size();
  outputparameters.device             = devicenr;
  outputparameters.sampleFormat       = paInt16;
  if (m_latency > 0)
    outputparameters.suggestedLatency = m_latency / 1000000.0;
  else
    outputparameters.suggestedLatency = deviceinfo->defaultLowOutputLatency;


  int formatsupported = Pa_IsFormatSupported(NULL, &outputparameters, m_rate);
  if (formatsupported != paFormatIsSupported)
  {
    LogError("%s: format not supported: %s", m_name.c_str(), Pa_GetErrorText(formatsupported));
    return false;
  }

  err = Pa_OpenStream(&m_stream, NULL, &outputparameters, m_rate, m_period, paNoFlag, PaStreamCallback, (void*)this);
  if (err != paNoError)
  {
    LogError("%s: %s", m_name.c_str(), Pa_GetErrorText(err));
    return false;
  }
  m_opened = true;

  m_outputvalues.resize(m_channels.size());

  err = Pa_StartStream(m_stream);
  if (err != paNoError)
  {
    LogError("%s: %s", m_name.c_str(), Pa_GetErrorText(err));
    return false;
  }
  m_started = true;

  m_pwmphase = 0x7FFF;
  m_pwmperiod = Round32((double)m_rate / 93.75); //this will use 512 samples on 48 kHz
  m_pwmcount = 0;

  return true;
}

bool CDeviceSound::WriteOutput()
{
  m_callbacksignal = false; //reset the callback signal
  USleep(1000000LL);        //give the callback one second to set the signal

  if (m_stop)
    return true;

  if (!m_callbacksignal) //if it didn't set it, give it one more second
  {
    USleep(1000000LL);

    if (m_stop)
      return true;

    if (!m_callbacksignal)
    {
      LogError("%s: portaudio callback not responding", m_name.c_str());
      return false;
    }
  }

  return true;
}

void CDeviceSound::CloseDevice()
{
  int err;

  //shut down anything we opened in reverse order

  if (m_started)
  {
    err = Pa_AbortStream(m_stream);
    if (err != paNoError)
      LogError("%s: %s", m_name.c_str(), Pa_GetErrorText(err));

    m_started = false;
  }

  if (m_opened)
  {
    err = Pa_CloseStream(m_stream);
    if (err != paNoError)
      LogError("%s: %s", m_name.c_str(), Pa_GetErrorText(err));

    m_opened = false;
  }

  if (m_initialized)
  {
    err = g_portaudioinit.DeInit();
    if (err != paNoError)
      LogError("%s: %s", m_name.c_str(), Pa_GetErrorText(err));

    m_initialized = false;
  }
    
  return;
}


int CDeviceSound::PaStreamCallback(const void *input, void *output, unsigned long framecount,
				   const PaStreamCallbackTimeInfo* timeinfo, PaStreamCallbackFlags statusflags,
				   void *userdata) 
{
  CDeviceSound* thisdevice = (CDeviceSound*)userdata;
  int16_t* out = (int16_t*)output;

  thisdevice->FillOutput(out, framecount);
 
  thisdevice->m_callbacksignal = true;

  if (thisdevice->m_stop)
    return paAbort;
  else
    return paContinue;
}

void CDeviceSound::FillOutput(int16_t* out, unsigned long framecount)
{
  //get the channel values from the clienshandler
  int64_t now = GetTimeUs();
  m_clients.FillChannels(m_channels, now, this);

  //store the values from m_channels, because they get recalculated for each call to GetValue()
  for (int i = 0; i < m_channels.size(); i++)
  {
    int out = Round32(m_channels[i].GetValue(now) * m_pwmperiod);
    m_outputvalues[i] = Clamp(out, 0, m_pwmperiod);
  }

  //calculate the pwm wave for each channnel
  for (int i = 0; i < framecount; i++)
  {
    for (int j = 0; j < m_channels.size(); j++)
    {
      if (m_pwmcount < m_outputvalues[j])
	*out++ = m_pwmphase;
      else
        *out++ = 0;
    } 

    m_pwmcount++;
    if (m_pwmcount == m_pwmperiod)
    {
      m_pwmcount = 0;
      m_pwmphase = ~m_pwmphase;
    }
  }
}

