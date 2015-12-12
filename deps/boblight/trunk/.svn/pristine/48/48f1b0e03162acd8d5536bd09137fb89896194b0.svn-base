/*
 * boblight
 * Copyright (C) Bob  2012 
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

#ifndef CDEVICESPI
#define CDEVICESPI

#include "device.h"

class CDeviceSPI : public CDevice
{
  public:
    CDeviceSPI(CClientsHandler& clients);
    void Sync();

  protected:

    bool SetupDevice();
    bool WriteOutput();
    void CloseDevice();

    bool WriteBuffer();

    CSignalTimer m_timer;
    int          m_fd;
    uint8_t*     m_buff;
    int          m_buffsize;
    float        m_max;
};


#endif //CDEVICESPI
