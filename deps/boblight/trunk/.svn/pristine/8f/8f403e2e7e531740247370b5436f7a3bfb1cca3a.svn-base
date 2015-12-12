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

#ifndef CDEVICERS232
#define CDEVICERS232

#include "device.h"
#include "util/serialport.h"

class CDeviceRS232 : public CDevice
{
  public:
    CDeviceRS232(CClientsHandler& clients);

    void SetPrefix(std::vector<uint8_t> prefix)   { m_prefix = prefix; }
    void SetPostfix(std::vector<uint8_t> postfix) { m_postfix = postfix; }
    void SetType(int type);
    void SetMax(int64_t max) { m_max = max; }

    void Sync();

  protected:

    bool SetupDevice();
    bool WriteOutput();
    void CloseDevice();
    
    bool OpenSerialPort();

    CSignalTimer m_timer;
    CSerialPort  m_serialport;

    uint8_t*             m_buff;
    int                  m_buffsize;
    std::vector<uint8_t> m_prefix;
    std::vector<uint8_t> m_postfix;
    int64_t              m_max;
    int                  m_bytes;
};

#endif //CDEVICERS232
