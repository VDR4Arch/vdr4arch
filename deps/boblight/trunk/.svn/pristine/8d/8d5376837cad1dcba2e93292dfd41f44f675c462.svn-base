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

#include <string.h>
#include <iostream> //debug
#include "messagequeue.h"
#include "timeutils.h"

using namespace std;

//return the oldest message, which is at the front of the queue
CMessage CMessageQueue::GetMessage()
{
  CMessage message;
  if (m_messages.empty())
    return message;
  
  message = m_messages[0];
  m_messages.erase(m_messages.begin());
  return message;
}

void CMessageQueue::AddData(std::string data)
{
  int64_t now = GetTimeUs();
  int nlpos = data.find('\n'); //position of the newline

  //no newline
  if (nlpos == string::npos)
  {
    //set the timestamp if there's no remaining data
    if (m_remainingdata.message.empty())
      m_remainingdata.time = now;

    m_remainingdata.message += data;
    return;
  }

  //add the data from the last time
  //if there is none, use the now timestamp
  CMessage message = m_remainingdata;
  if (message.message.empty())
    message.time = now;

  while(nlpos != string::npos)
  {
    message.message += data.substr(0, nlpos); //get the string until the newline
    m_messages.push_back(message);            //put the message in the queue

    //reset the message
    message.message.clear();
    message.time = now;

    if (nlpos + 1 >= data.length()) //if the newline is at the end of the string, we're done here
    {
      data.clear();
      break;
    }
    
    data = data.substr(nlpos + 1); //remove all the data up to and including the newline
    nlpos = data.find('\n'); //search for a new newline
  }

  //save the remaining data with the timestamp
  m_remainingdata.message = data;
  m_remainingdata.time = now;
}

void CMessageQueue::AddData(char* data, int size)
{
  char* strdata = new char[size + 1];

  memcpy(strdata, data, size);
  strdata[size] = 0;
  AddData(strdata);

  delete strdata;
}

void CMessageQueue::Clear()
{
  m_remainingdata.message.clear();
  m_messages.clear();
}
