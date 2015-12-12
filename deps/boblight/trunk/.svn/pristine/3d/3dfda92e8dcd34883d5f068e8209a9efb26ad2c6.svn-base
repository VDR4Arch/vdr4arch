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

#ifndef FLAGMANAGERV4L
#define FLAGMANAGERV4L

#include <string>

#include "clients/flagmanager.h"

class CFlagManagerV4l : public CFlagManager
{
  public:
    CFlagManagerV4l();

    void        ParseFlagsExtended(int& argc, char**& argv, int& c, char*& optarg); //we load our own flags here
    void        PrintHelpMessage();

    std::string m_device;
    const char* m_standard;
    int         m_channel;
    bool        m_checksignal;

    int         m_width;
    int         m_height;

    bool        m_debug;
    const char* m_debugdpy;

    std::string m_customcodec;
    
  private:
    std::string m_strdebugdpy;
    std::string m_strstandard;
    
};

#endif //FLAGMANAGERV4L