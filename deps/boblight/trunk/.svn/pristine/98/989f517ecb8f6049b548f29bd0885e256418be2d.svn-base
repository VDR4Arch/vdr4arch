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

#ifndef CONFIGURATION
#define CONFIGURATION

#include <string>
#include <vector>

#include "config.h"
#include "light.h"
#include "client.h"
#include "device/device.h"
#include "device/devicers232.h"
#include "device/devicedioder.h"
#include "device/deviceambioder.h"

#ifdef HAVE_LIBPORTAUDIO
  #include "device/devicesound.h"
#endif
#ifdef HAVE_LIBUSB
  #include "device/deviceusb.h"
#endif
#ifdef HAVE_LINUX_SPI_SPIDEV_H
  #include "device/devicespi.h"
#endif

//place to store relevant lines from the config file
class CConfigLine
{
  public:
    CConfigLine(std::string linestr, int iline)
    {
      linenr = iline;
      line = linestr;
    }
    
    int linenr;
    std::string line;
};

//place to group config lines
class CConfigGroup
{
  public:
    std::vector<CConfigLine> lines;
};

class CConfig
{
  public:
    bool LoadConfigFromFile(std::string file);
    bool CheckConfig(); //checks lines in the config file to make sure the syntax is correct

    //builds the config
    bool BuildConfig(CClientsHandler& clients, std::vector<CDevice*>& devices, std::vector<CLight>& lights);

  private:
    std::string m_filename; //filename of the config file

    //config lines groups
    std::vector<CConfigLine>  m_globalconfiglines;
    std::vector<CConfigGroup> m_devicelines;
    std::vector<CConfigGroup> m_colorlines;
    std::vector<CConfigGroup> m_lightlines;

    //prints config to log
    void PrintConfig();
    void TabsToSpaces(std::string& line);

    //syntax config checks
    bool CheckGlobalConfig();
    bool CheckDeviceConfig();
    bool CheckColorConfig();
    bool CheckLightConfig();

    //gets a config line that starts with key
    int  GetLineWithKey(std::string key, std::vector<CConfigLine>& lines, std::string& line);

    void BuildClientsHandlerConfig(CClientsHandler& clients);
    bool BuildColorConfig(std::vector<CColor>& colors);
    bool BuildDeviceConfig(std::vector<CDevice*>& devices, CClientsHandler& clients);
    bool BuildLightConfig(std::vector<CLight>& lights, std::vector<CDevice*>& devices, std::vector<CColor>& colors);

    bool BuildPopen(CDevice*& device, int devicenr, CClientsHandler& clients);
#ifdef HAVE_OLA
    bool BuildOla(CDevice*& device, int devicenr, CClientsHandler& clients);
#endif
    bool BuildRS232(CDevice*& device, int devicenr, CClientsHandler& clients, const std::string& type);
    bool BuildLtbl(CDevice*& device,  int devicenr, CClientsHandler& clients);
    bool BuildDioder(CDevice*& device, int devicenr, CClientsHandler& clients);
    bool BuildAmbioder(CDevice*& device, int devicenr, CClientsHandler& clients);
    bool SetDevicePrecision(CDeviceAmbioder*& device, int devicenr);

#ifdef HAVE_LIBPORTAUDIO
    bool BuildSound(CDevice*& device, int devicenr, CClientsHandler& clients);
#endif
#ifdef HAVE_LIBUSB
    bool BuildiBeLight(CDevice*& device, int devicenr, CClientsHandler& clients);
    bool BuildLightpack(CDevice*& device, int devicenr, CClientsHandler& clients);
#endif
#ifdef HAVE_LINUX_SPI_SPIDEV_H
    bool BuildSPI(CDevice*& device, int devicenr, CClientsHandler& clients, const std::string& type);
#endif

    bool SetDeviceName(CDevice* device, int devicenr);
    bool SetDeviceOutput(CDevice* device, int devicenr);
    bool SetDeviceChannels(CDevice* device, int devicenr);
    bool SetDeviceRate(CDevice* device, int devicenr);
    bool SetDeviceInterval(CDevice* device, int devicenr);
    void SetDevicePrefix(CDeviceRS232* device, int devicenr);
    void SetDevicePostfix(CDeviceRS232* device, int devicenr);
#ifdef HAVE_LIBPORTAUDIO
    bool SetDevicePeriod(CDeviceSound* device, int devicenr);
    void SetDeviceLatency(CDeviceSound* device, int devicenr);
#endif
#ifdef HAVE_LIBUSB
    void SetDeviceBus(CDeviceUsb* device, int devicenr);
    void SetDeviceAddress(CDeviceUsb* device, int devicenr);
    void SetSerial(CDeviceUsb* device, int devicenr);
#endif
    void SetDeviceAllowSync(CDevice* device, int devicenr);
    void SetDeviceDebug(CDevice* device, int devicenr);
    bool SetDeviceBits(CDeviceRS232* device, int devicenr);
    bool SetDeviceMax(CDeviceRS232* device, int devicenr);
    void SetDeviceDelayAfterOpen(CDevice* device, int devicenr);
    void SetDeviceThreadPriority(CDevice* device, int devicenr);

    bool SetLightName(CLight& light, std::vector<CConfigLine>& lines, int lightnr);
    void SetLightScanRange(CLight& light, std::vector<CConfigLine>& lines);
};

#endif //CONFIGURATION
