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

#ifndef CDEVICESOUND
#define CDEVICESOUND

#include <vector>
#include <portaudio.h>
#include "device.h"
#include "util/condition.h"

class CDeviceSound : public CDevice
{
  public:
    CDeviceSound(CClientsHandler& clients);

    void SetLatency(double latency) { m_latency = latency; }
    void SetPeriod(int period)      { m_period = period; }
 
  private:
    bool SetupDevice();
    bool WriteOutput();
    void CloseDevice();

    PaStream*  m_stream;          //handle for portaudio

    bool       m_opened;          //if we have anything opened on m_stream that we need to close
    bool       m_initialized;     //if portaudio was successfully initialized
    bool       m_started;         //if we started a stream that we need to stop

    volatile bool m_callbacksignal;  //signal sent from the portaudio callback,
                                     //used as a check to make sure the callback is still working

    double     m_latency;         //latency in milliseconds
    int        m_period;          //period in samples
 
    int16_t    m_pwmphase;        //phase of the pwm, gets flipped when pwmcount hits pwmperiod
    int        m_pwmperiod;       //size of the pwm period in samples
    int        m_pwmcount;        //current pwm position

    std::vector<int16_t> m_outputvalues; //where we store channel output values

    //portaudio callback
    static int PaStreamCallback(const void *input, void *output, unsigned long framecount,
			        const PaStreamCallbackTimeInfo* timeinfo, PaStreamCallbackFlags statusflags,
				void *userdata);
    //where we fill the buffer going to the soundcard
    void       FillOutput(int16_t* out, unsigned long framecount);
};

#endif //CDEVICESOUND
