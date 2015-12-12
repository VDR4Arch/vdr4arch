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

void setup()
{
  Serial.begin(38400);
}

//uncomment one of the lines below to match your arduino
//#define DUEMILANOVE
//#define MEGA

//this could be done automatically, but then I have to check
//if newer arduino boards are released etc etc, meh (I tried, it sucked)

//on the Arduino megam, 12 pwm outputs are available, on the duemilanove there are 6
#ifdef MEGA
  //mega
  uint8_t outputs[] = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};
#elif defined(DUEMILANOVE)
  //duemilanove
  uint8_t outputs[] = {3, 5, 6, 9, 10, 11};
#else
  #error please uncomment a line matching your arduino board (you're actually required to edit the code now)
  uint8_t outputs[] = {0};
#endif

#define NROUTPUTS (sizeof(outputs))
uint8_t values[NROUTPUTS];

void loop()
{
  WaitForPrefix();

  for (uint8_t i = 0; i < NROUTPUTS; i++)
  {
    while(!Serial.available());
    values[i] = Serial.read();
  }
  
  for (uint8_t i = 0; i < NROUTPUTS; i++)
    analogWrite(outputs[i], values[i]);
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
