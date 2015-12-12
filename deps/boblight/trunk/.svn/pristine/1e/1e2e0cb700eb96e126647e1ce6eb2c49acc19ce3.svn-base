/*
 * deviceola.h
 Copyright (C) Hippy 2010
  
* Use OLA (and all it's dmx/ethernet output devices) with boblightd
* Find ola and instructions at http://www.opendmx.net/index.php/Open_Lighting_Architecture

###############################################################
          Licensed under WTFPL - Code by Hippy 2010...
###############################################################
 See http://sam.zoy.org/wtfpl/
*/


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

#ifndef CDEVICEOLA

#define CDEVICEOLA

#include <stdio.h>
#include "device.h"
#include <ola/StreamingClient.h>

#define F2B(f) ((f) >= 1.0 ? 255 : (int)((f)*256.0))  // convert floats to 0..255 for 8-bit dmx

class CDeviceOla : public CDevice
{
  public:
    CDeviceOla (CClientsHandler& clients); // get setup
    void Sync();  // thats how we roll

  private:
    bool SetupDevice();  // create a client and connect to ola
    bool WriteOutput();  // send dmx to ola
    void CloseDevice();  // close the ola client

    ola::StreamingClient m_client;  // our simple setup ola client object

    ola::DmxBuffer m_outbuffer;  // setup a dmx buffer
    int m_universe;   // ola universe we are sending to

    CSignalTimer m_timer; // timer
};

#endif
