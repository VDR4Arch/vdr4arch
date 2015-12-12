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

#include "Tlc5940.h"

void setup()
{
  Tlc.init();
  Serial.begin(38400);
}

void loop()
{
  WaitForPrefix();
  
  for (int i = 0; i < NUM_TLCS * 16; i++)
  {
    //read out two bytes for each channel, big endian
    while(!Serial.available());
    uint16_t out = Serial.read() << 8;
    while(!Serial.available());
    out |= Serial.read();
    //set the tlc5940 channel to the read value
    Tlc.set(i, out);
  }
  Tlc.update();
}

//boblightd needs to send 0x55 0xAA before sending the channel bytes
void WaitForPrefix()
{
  uint8_t first = 0, second = 0;
  while (second != 0x55 || first != 0xAA)
  {
    while (!Serial.available());
    second = first;
    first = Serial.read();
  }
}

