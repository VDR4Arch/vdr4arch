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

#include <iostream>//debug

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

#include "serialport.h"
#include "misc.h"
#include "baudrate.h"
#include "timeutils.h"

using namespace std;

CSerialPort::CSerialPort()
{
  m_fd       = -1;
  m_tostdout = false;
}

CSerialPort::~CSerialPort()
{
  Close();
}

int CSerialPort::Write(uint8_t* data, int len)
{
  fd_set port;
  
  if (m_fd == -1)
  {
    m_error = "port closed";
    return -1;
  }

  int byteswritten = 0;

  while (byteswritten < len)
  {
    FD_ZERO(&port);
    FD_SET(m_fd, &port);
    int returnv = select(m_fd + 1, NULL, &port, NULL, NULL);
    if (returnv == -1)
    {
      m_error = "select() " + GetErrno();
      return -1;
    }

    returnv = write(m_fd, data + byteswritten, len - byteswritten);
    if (returnv == -1)
    {
      m_error = "write() " + GetErrno();
      return -1;
    }
    byteswritten += returnv;
  }

  //print what's written to stdout for debugging
  if (m_tostdout)
  {
    printf("%s write:", m_name.c_str());
    for (int i = 0; i < byteswritten; i++)
      printf(" %02x", (unsigned int)data[i]);

    printf("\n");
  }

  return byteswritten;
}

int CSerialPort::Read(uint8_t* data, int len, int64_t usecs /*= -1*/)
{
  fd_set port;
  struct timeval timeout, *tv;

  if (m_fd == -1)
  {
    m_error = "port closed";
    return -1;
  }

  int64_t now = GetTimeUs();
  int64_t target = now + usecs;
  int     bytesread = 0;

  while (bytesread < len)
  {
    if (usecs < 0)
    {
      tv = NULL;
    }
    else
    {
      if (now >= target)
      {
        m_error = "read timed out";
        return -1;
      }
      
      timeout.tv_sec  = (target - now) / 1000000LL;
      timeout.tv_usec = (target - now) % 1000000LL;
      tv = &timeout;
    }

    FD_ZERO(&port);
    FD_SET(m_fd, &port);
    int returnv = select(m_fd + 1, &port, NULL, NULL, tv);

    if (returnv == -1)
    {
      m_error = "select() " + GetErrno();
      return -1;
    }
    else if (returnv == 0)
    {
      m_error = "read timed out";
      return -1;
    }

    returnv = read(m_fd, data + bytesread, len - bytesread);
    if (returnv == -1)
    {
      m_error = "read() " + GetErrno();
      return -1;
    }

    bytesread += returnv;

    now = GetTimeUs();
  }

  //print what's read to stdout for debugging
  if (m_tostdout)
  {
    printf("%s read:", m_name.c_str());
    for (int i = 0; i < bytesread; i++)
      printf(" %02x", (unsigned int)data[i]);

    printf("\n");
  }

  return bytesread;
}

//setting all this stuff up is a pain in the ass
bool CSerialPort::Open(std::string name, int baudrate, int databits/* = 8*/, int stopbits/* = 1*/, int parity/* = PAR_NONE*/)
{
  m_name = name;
  m_error.clear();
  
  if (databits < 5 || databits > 8)
  {
    m_error = "Databits has to be between 5 and 8";
    return false;
  }

  if (stopbits != 1 && stopbits != 2)
  {
    m_error = "Stopbits has to be 1 or 2";
    return false;
  }

  if (parity != PAR_NONE && parity != PAR_EVEN && parity != PAR_ODD)
  {
    m_error = "Parity has to be none, even or odd";
    return false;
  }

  m_fd = open(name.c_str(), O_RDWR | O_NOCTTY);

  if (m_fd == -1)
  {
    m_error = "open() " + GetErrno();
    return false;
  }

  //make sure port is blocking
  int flags = fcntl(m_fd, F_GETFL, 0);
  fcntl(m_fd, F_SETFL, flags & (~O_NONBLOCK));

  //set port attributes, don't bail if they fail because the port might still be usable
  if (tcgetattr(m_fd, &m_options) == 0)
  {
    SetBaudRate(baudrate);
    SetPortOptions(databits, stopbits, parity);
  }
  else
  {
    m_error = "tcgetattr() " + GetErrno();
  }

  //make port non blocking
  flags = fcntl(m_fd, F_GETFL, 0);
  fcntl(m_fd, F_SETFL, flags | O_NONBLOCK);

  return true;
}

void CSerialPort::Close()
{
  if (m_fd != -1)
  {
    close(m_fd);
    m_fd = -1;
    m_name = "";
    m_error = "";
  }
}

bool CSerialPort::HasError()
{
  return !m_error.empty();
}

string CSerialPort::GetError()
{
  return m_name + ": " + m_error;
}

bool CSerialPort::SetBaudRate(int baudrate)
{
  int rate = IntToRate(baudrate);
  if (rate == -1)
  {
    char buff[255];
    sprintf(buff, "%i is not a valid baudrate", baudrate);
    m_error = buff;
    return false;
  }
  
  if (cfsetispeed(&m_options, rate) != 0)
  {
    m_error = "cfsetispeed() " + GetErrno();
    return false;
  }
  
  if (cfsetospeed(&m_options, rate) != 0)
  {
    m_error = "cfsetospeed() " + GetErrno();
    return false;
  }

  return true;
}

int CSerialPort::IntToRate(int baudrate)
{
  for (int i = 0; i < sizeof(baudrates) / sizeof(sbaudrate) - 1; i++)
  {
    if (baudrates[i].rate == baudrate)
    {
      return baudrates[i].symbol;
    }
  }
  return -1;
}

bool CSerialPort::SetPortOptions(int databits, int stopbits, int parity)
{
  m_options.c_cflag |= (CLOCAL | CREAD);
  m_options.c_cflag &= ~HUPCL;

  m_options.c_cflag &= ~CSIZE;
  if (databits == 5) m_options.c_cflag |= CS5;
  if (databits == 6) m_options.c_cflag |= CS6;
  if (databits == 7) m_options.c_cflag |= CS7;
  if (databits == 8) m_options.c_cflag |= CS8;

  m_options.c_cflag &= ~PARENB;
  if (parity == PAR_EVEN || parity == PAR_ODD)
    m_options.c_cflag |= PARENB;
  if (parity == PAR_ODD)
    m_options.c_cflag |= PARODD;

#ifdef CRTSCTS
  m_options.c_cflag &= ~CRTSCTS;
#elif defined(CNEW_RTSCTS)
  m_options.c_cflag &= ~CNEW_RTSCTS;
#endif

  if (stopbits == 1) m_options.c_cflag &= ~CSTOPB;
  else m_options.c_cflag |= CSTOPB;
  
  //I guessed a little here
  m_options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG | ECHOK | ECHONL | ECHOCTL | ECHOKE | TOSTOP);
#ifdef XCASE //freebsd doesn't have XCASE
  m_options.c_lflag &= ~XCASE;
#endif
#ifdef ECHOPRT
  m_options.c_lflag &= ~ECHOPRT;
#endif
  
  if (parity == PAR_NONE)
  {
    m_options.c_iflag &= ~INPCK;
  }
  else
  {
    m_options.c_iflag |= INPCK | ISTRIP;
  }

  m_options.c_iflag &= ~(IXON | IXOFF | IXANY | BRKINT | INLCR | IGNCR | ICRNL | IMAXBEL);
#ifdef IUCLC //freebsd doesn't have IUCLC
  m_options.c_iflag &= ~IUCLC;
#endif

  m_options.c_oflag &= ~(OPOST | ONLCR | OCRNL);

  if (tcsetattr(m_fd, TCSANOW, &m_options) != 0)
  {
    string error = "tcsetattr() " + GetErrno();
    if (m_error.empty())
      m_error = error;
    else
      m_error += ", " + error; //use += so we don't lose the error from SetBaudRate

    return false;
  }

  return true;
}

