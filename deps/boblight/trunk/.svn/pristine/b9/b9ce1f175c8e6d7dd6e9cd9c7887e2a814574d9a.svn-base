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

#ifndef CLIGHT
#define CLIGHT

#include "util/inclstdint.h"

#include <string>
#include <vector>
#include <string.h>
#include <utility>

#include "util/misc.h"

class CDevice; //forward declare

class CColor
{
  public:
    CColor();

    void        SetName(std::string name) { m_name = name; }
    std::string GetName()                 { return m_name; }

    void SetGamma(float gamma)           { m_gamma = gamma; }
    void SetAdjust(float adjust)         { m_adjust = adjust; }
    void SetBlacklevel(float blacklevel) { m_blacklevel = blacklevel; }
    void SetRgb(float (&rgb)[3])         { memcpy(m_rgb, rgb, sizeof(m_rgb)); }
    
    float  GetGamma()      { return m_gamma; }
    float  GetAdjust()     { return m_adjust; }
    float  GetBlacklevel() { return m_blacklevel; }
    float* GetRgb()        { return m_rgb; }
    
  private:
    std::string m_name;
    
    float m_rgb[3];
    float m_gamma;
    float m_adjust;
    float m_blacklevel;
};
    
class CLight
{
  public:
    CLight();

    void        SetName(std::string name)      { m_name = name; }
    std::string GetName()                      { return m_name; }
    
    void  SetRgb(float (&rgb)[3], int64_t time);

    void  SetUse(bool use)                     { m_use = use; }
    void  SetInterpolation(bool interpolation) { m_interpolation = interpolation; }
    void  SetSpeed(float speed)                { m_speed = Clamp(speed, 0.0, 100.0); }
    void  SetSingleChange(float singlechange);
    bool  GetUse()                             { return m_use; }
    bool  GetInterpolation()                   { return m_interpolation; }
    float GetSpeed()                           { return m_speed; }
    float GetSingleChange(CDevice* device);
    void  ResetSingleChange(CDevice* device);

    void  AddColor(CColor& color)              { m_colors.push_back(color); }
    int   GetNrColors()                        { return m_colors.size(); };
    
    float GetGamma(int colornr)                { return m_colors[colornr].GetGamma(); }
    float GetAdjust(int colornr)               { return m_colors[colornr].GetAdjust(); }
    float GetBlacklevel(int colornr)           { return m_colors[colornr].GetBlacklevel(); }
    float GetColorValue(int colornr, int64_t time);

    void   SetHscan(float* hscan) { m_hscan[0] = hscan[0]; m_hscan[1] = hscan[1]; }
    void   SetVscan(float* vscan) { m_vscan[0] = vscan[0]; m_vscan[1] = vscan[1]; }
    float* GetVscan()                          { return m_vscan; }
    float* GetHscan()                          { return m_hscan; }

    int      GetNrUsers()                      { return m_users.size(); }
    void     AddUser(CDevice* device);
    void     ClearUser(CDevice* device);
    CDevice* GetUser(unsigned int user)        { return m_users[user].first; }
    
  private:
    std::string m_name;
    
    int64_t m_time;        //current write time
    int64_t m_prevtime;    //previous write time

    float   m_rgb[3];
    float   m_prevrgb[3];
    float   m_speed;

    bool    m_interpolation;
    bool    m_use;

    std::vector<CColor> m_colors;

    float   m_hscan[2];
    float   m_vscan[2];
    
    float   FindMultiplier(float *rgb, float ceiling);
    float   FindMultiplier(float *rgb, float *ceiling);

    std::vector<std::pair<CDevice*, float> > m_users; //devices using this light
};

#endif //CLIGHT
