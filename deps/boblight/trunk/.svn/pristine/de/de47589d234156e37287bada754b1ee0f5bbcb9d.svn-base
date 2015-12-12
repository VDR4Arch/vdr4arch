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

#ifndef GRABBERXGETIMAGE
#define GRABBERXGETIMAGE

#include "grabber-base.h"

//class for grabbing with slow xgetimage
class CGrabberXGetImage : public CGrabber
{
  public:
    CGrabberXGetImage(void* boblight, volatile bool& stop, bool sync);
    ~CGrabberXGetImage();
    
    bool Run();
    bool ExtendedSetup();
    
  private:

    XImage* m_debugxim;                //this is were we store captured pixels
};

#endif //GRABBERXGETIMAGE
