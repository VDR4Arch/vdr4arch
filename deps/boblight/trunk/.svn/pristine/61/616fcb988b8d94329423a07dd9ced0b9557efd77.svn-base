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

#include <iostream>
#include <float.h>

#include "light.h"

using namespace std;

CColor::CColor()
{
  memset(m_rgb, 0, sizeof(m_rgb));
  m_gamma = 1.0;
  m_adjust = 1.0;
  m_blacklevel = 0.0;
}

CLight::CLight()
{
  m_time = -1;
  m_prevtime = -1;

  for (int i = 0; i < 3; i++)
  {
    m_rgb[i] = 0.0;
    m_prevrgb[i] = 0.0;
  }

  m_speed = 100.0;
  m_use = true;
  m_interpolation = false;

  m_hscan[0] = 0.0;
  m_hscan[1] = 100.0;
  m_vscan[0] = 0.0;
  m_vscan[1] = 100.0;
}

void CLight::SetRgb(float (&rgb)[3], int64_t time)
{
  for (int i = 0; i < 3; i++)
    rgb[i] = Clamp(rgb[i], 0.0, 1.0);
  
  memcpy(m_prevrgb, m_rgb, sizeof(m_prevrgb));
  memcpy(m_rgb, rgb, sizeof(m_rgb));

  m_prevtime = m_time;
  m_time = time;
}

float CLight::GetColorValue(int colornr, int64_t time)
{
  if (m_interpolation && m_prevtime == -1) //need two writes for interpolation
    return 0.0;

  float rgb[3];
  if (m_interpolation)
  {
    float multiply = 0.0;
    if ((float)(m_time - m_prevtime) > 0.0) //don't want to divide by 0
    {
      multiply = (float)(time - m_time) / (float)(m_time - m_prevtime);
    }
    multiply = Clamp(multiply, 0.0, 1.0);
    for (int i = 0; i < 3; i++)
    {
      float diff = m_rgb[i] - m_prevrgb[i];
      rgb[i] = m_prevrgb[i] + (diff * multiply);
    }
  }
  else
  {
    memcpy(rgb, m_rgb, sizeof(rgb));
  }

  if (rgb[0] == 0.0 && rgb[1] == 0.0 && rgb[2] == 0.0)
    return 0.0;
  
  float maxrgb[3] = {0.0, 0.0, 0.0};
  for (int i = 0; i < m_colors.size(); i++)
  {
    for (int j = 0; j < 3; j++)
      maxrgb[j] += m_colors[i].GetRgb()[j];
  }

  float expandvalue = FindMultiplier(rgb, 1.0);
  for (int i = 0; i < 3; i++)
    rgb[i] *= expandvalue;

  float range = FindMultiplier(rgb, maxrgb);
  for (int i = 0; i < 3; i++)
    rgb[i] *= range;  

  float colorvalue;
  for (int i = 0; i <= colornr; i++)
  {
    colorvalue = FindMultiplier(m_colors[i].GetRgb(), rgb);
    colorvalue = Clamp(colorvalue, 0.0, 1.0);
    
    for (int j = 0; j < 3; j++)
    {
      rgb[j] -= m_colors[i].GetRgb()[j] * colorvalue;
    }
  }

  return colorvalue / expandvalue;
}

float CLight::FindMultiplier(float *rgb, float ceiling)
{
  float multiplier = FLT_MAX;

  for (int i = 0; i < 3; i++)
  {
    if (rgb[i] > 0.0)
    {
      if (ceiling / rgb[i] < multiplier)
        multiplier = ceiling / rgb[i];
    }
  }
  return multiplier;
}

float CLight::FindMultiplier(float *rgb, float *ceiling)
{
  float multiplier = FLT_MAX;

  for (int i = 0; i < 3; i++)
  {
    if (rgb[i] > 0.0)
    {
      if (ceiling[i] / rgb[i] < multiplier)
        multiplier = ceiling[i] / rgb[i];
    }
  }
  return multiplier;
}

void CLight::AddUser(CDevice* device)
{
  //add CDevice pointer to users if it doesn't exist yet
  for (unsigned int i = 0; i < m_users.size(); i++)
  {
    if (m_users[i].first == device)
      return;
  }

  m_users.push_back(make_pair(device, 0.0));
}

void CLight::ClearUser(CDevice* device)
{
  //clear CDevice* from users
  for (vector<pair<CDevice*, float> >::iterator it = m_users.begin(); it != m_users.end(); it++)
  {
    if ((*it).first == device)
    {
      m_users.erase(it);
      return;
    }
  }
}

void CLight::SetSingleChange(float singlechange)
{
  for (unsigned int i = 0; i < m_users.size(); i++)
    m_users[i].second = Clamp(singlechange, 0.0, 1.0);
}

float CLight::GetSingleChange(CDevice* device)
{
  for (unsigned int i = 0; i < m_users.size(); i++)
  {
    if (m_users[i].first == device)
      return m_users[i].second;
  }
  return 0.0;
}

void CLight::ResetSingleChange(CDevice* device)
{
  for (unsigned int i = 0; i < m_users.size(); i++)
  {
    if (m_users[i].first == device)
    {
      m_users[i].second = 0.0;
      return;
    }
  }
}

