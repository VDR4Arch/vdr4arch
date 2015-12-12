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

#ifndef CMESSAGEQUEUE
#define CMESSAGEQUEUE

#include "inclstdint.h"

#include <vector>
#include <string>

#define MAXDATA 100000 //max data sent without a newline, to prevent memleaks from bogus clients

class CMessage
{
  public:
    std::string message;
    int64_t time;
};

//message queue, splits data by newlines, also sets a timestamp for each message
class CMessageQueue
{
  public:
    int      GetNrMessages() { return m_messages.size();}
    CMessage GetMessage();
    void     AddData(char* data, int size);
    void     AddData(std::string data);

    int      GetRemainingDataSize() { return m_remainingdata.message.length(); }
    void     Clear();
  private:

    std::vector<CMessage> m_messages;
    CMessage              m_remainingdata;
};

#endif //CMESSAGEQUEUE
