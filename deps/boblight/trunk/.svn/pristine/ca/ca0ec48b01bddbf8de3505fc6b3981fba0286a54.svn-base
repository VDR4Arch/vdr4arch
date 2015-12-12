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

#include "flagmanager-v4l.h"
#include "videograbber.h"

#define BOBLIGHT_DLOPEN_EXTERN
#include "lib/boblight.h"

#include <string.h>
#include <iostream>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <linux/videodev2.h>

extern CFlagManagerV4l g_flagmanager;

using namespace std;

CVideoGrabber::CVideoGrabber()
{
  av_register_all();
  avdevice_register_all();
  av_log_set_level(AV_LOG_DEBUG);

  memset(&m_formatparams, 0, sizeof(m_formatparams));
  m_formatcontext = NULL;
  m_codeccontext = NULL;
  m_codec = NULL;
  m_inputframe = NULL;
  m_outputframe = NULL;
  m_sws = NULL;
  m_framebuffer = NULL;
  m_fd = -1;
  
  m_dpy = NULL;
}

CVideoGrabber::~CVideoGrabber()
{
  Cleanup();
}

void CVideoGrabber::Setup()
{
  int            returnv;
  AVInputFormat* inputformat;

  memset(&m_formatparams, 0, sizeof(m_formatparams));

  //set up the format we want
  m_formatparams.time_base.num = 1;
  m_formatparams.time_base.den = 60;
  m_formatparams.channel = g_flagmanager.m_channel;
  m_formatparams.width = g_flagmanager.m_width;
  m_formatparams.height = g_flagmanager.m_height;
  m_formatparams.standard = g_flagmanager.m_standard;
  m_formatparams.pix_fmt = PIX_FMT_BGR24;

  //open with custom codec when requested
  if (!g_flagmanager.m_customcodec.empty())
  {
    inputformat = av_find_input_format(g_flagmanager.m_customcodec.c_str());
    if (!inputformat)
      throw string ("Format " + g_flagmanager.m_customcodec + " not found");

    returnv = av_open_input_file(&m_formatcontext, g_flagmanager.m_device.c_str(), inputformat, 0, &m_formatparams);    
    if (returnv)
      throw string ("Unable to open " + g_flagmanager.m_device);
  }
  else
  {
    //try to open as video4linux2
    inputformat = av_find_input_format("video4linux2");
    returnv = -1;
    if (inputformat) //try to open as video4linux2 when available
    {
      returnv = av_open_input_file(&m_formatcontext, g_flagmanager.m_device.c_str(), inputformat, 0, &m_formatparams);
    }

    if (returnv) //failed, try to open as video4linux instead
    {
      inputformat = av_find_input_format("video4linux");
      if (!inputformat)
        throw string ("Unable to open " + g_flagmanager.m_device);

      returnv = av_open_input_file(&m_formatcontext, g_flagmanager.m_device.c_str(), inputformat, 0, &m_formatparams);

      if (returnv)
        throw string ("Unable to open " + g_flagmanager.m_device);
    }
  }

  if(av_find_stream_info(m_formatcontext) < 0)
    throw string ("Unable to find stream info");

  //print our format to stdout
  dump_format(m_formatcontext, 0, g_flagmanager.m_device.c_str(), false);

  //try to find the video stream
  m_videostream = -1;
  for (int i = 0; i < m_formatcontext->nb_streams; i++)
  {
    if (m_formatcontext->streams[i]->codec->codec_type == CODEC_TYPE_VIDEO)
    {
      m_videostream = i;
      break;
    }
  }

  if (m_videostream == -1)
    throw string("Unable to find a video stream");

  m_codeccontext = m_formatcontext->streams[m_videostream]->codec;
  m_codec = avcodec_find_decoder(m_codeccontext->codec_id);

  if (!m_codec)
    throw string("Unable to find a codec");

  returnv = avcodec_open(m_codeccontext, m_codec);
  if (returnv < 0)
    throw string("Unable to open codec");

  //check if we need to scale with libswscale
  m_needsscale =
    m_codeccontext->pix_fmt != PIX_FMT_BGR24 ||
    m_codeccontext->width   != g_flagmanager.m_width ||
    m_codeccontext->height  != g_flagmanager.m_height;

  //set up the frame that libavdecide will read the video4linux(2) data into
  m_inputframe = avcodec_alloc_frame();
  
  if (m_needsscale)
  {
    //set up the frame libswscale will write to
    m_outputframe = avcodec_alloc_frame();

    m_sws = sws_getContext(m_codeccontext->width, m_codeccontext->height, m_codeccontext->pix_fmt, 
                           g_flagmanager.m_width, g_flagmanager.m_height, PIX_FMT_BGR24, SWS_FAST_BILINEAR, NULL, NULL, NULL);

    if (!m_sws)
      throw string("Unable to get sws context");

    int buffsize = avpicture_get_size(PIX_FMT_RGB24, g_flagmanager.m_width, g_flagmanager.m_height);
    m_framebuffer = (uint8_t*)av_malloc(buffsize);

    avpicture_fill((AVPicture *)m_outputframe, m_framebuffer, PIX_FMT_BGR24, g_flagmanager.m_width, g_flagmanager.m_height);
  }

  //open video device for signal checking
  if (g_flagmanager.m_checksignal)
  {
    struct v4l2_capability capabilities = {};
    m_fd = open(g_flagmanager.m_device.c_str(), O_RDWR, 0);
    if (m_fd == -1)
      throw string("Unable to open " + g_flagmanager.m_device);

    //check if this is a v4l2 device
    if (ioctl(m_fd, VIDIOC_QUERYCAP, &capabilities) == -1)
      throw g_flagmanager.m_device + ":" + string(strerror(errno));
  }
  
  if (g_flagmanager.m_debug)
  {
    m_dpy = XOpenDisplay(g_flagmanager.m_debugdpy);
    if (!m_dpy)
      throw string("Unable to open display");

    m_window = XCreateSimpleWindow(m_dpy, RootWindow(m_dpy, DefaultScreen(m_dpy)), 0, 0,
                                   g_flagmanager.m_width, g_flagmanager.m_height, 0, 0, 0);
    m_gc = XCreateGC(m_dpy, m_window, 0, NULL);

    //lazy way of creating an ximage
    m_xim = XGetImage(m_dpy, RootWindow(m_dpy, DefaultScreen(m_dpy)), 0, 0, g_flagmanager.m_width,
                      g_flagmanager.m_height, AllPlanes, ZPixmap);
    
    XMapWindow(m_dpy, m_window);
    XSync(m_dpy, False);
  }
}

void CVideoGrabber::Run(volatile bool& stop, void* boblight)
{
  AVPacket pkt;

  int priority = -1;
 
  //tell libboblight how big our image is
  boblight_setscanrange(boblight, g_flagmanager.m_width, g_flagmanager.m_height);

  while(av_read_frame(m_formatcontext, &pkt) >= 0) //read videoframe
  {
    if (stop)
    {
      av_free_packet(&pkt);
      break;
    }
    
    if (!CheckSignal())
    {
      av_free_packet(&pkt);
      if (priority != 255)
      {
        priority = 255;
        cout << "No signal, setting priority to " << priority << "\n";
        boblight_setpriority(boblight, priority);
      }
      sleep(1);
      continue;
    }

    if (priority != g_flagmanager.m_priority)
    {
      priority = g_flagmanager.m_priority;
      cout << "Got signal, setting priority to " << priority << "\n";
      boblight_setpriority(boblight, priority);
    }
    
    if (pkt.stream_index == m_videostream)
    {
      int framefinished;

#if LIBAVCODEC_VERSION_INT >= AV_VERSION_INT(52,23,0)
      avcodec_decode_video2(m_codeccontext, m_inputframe, &framefinished, &pkt);
#else
      avcodec_decode_video(m_codeccontext, m_inputframe, &framefinished, pkt.data, pkt.size);
#endif

      if (framefinished)
      {
        uint8_t* outputptr;
        int      linesize;
        
        if (m_needsscale) //scale and assign pointer to output frame
        {
          sws_scale(m_sws, m_inputframe->data, m_inputframe->linesize, 0,
                    m_codeccontext->height, m_outputframe->data, m_outputframe->linesize);
          outputptr = m_framebuffer;
          linesize = m_outputframe->linesize[0];
        }
        else //assign pointer to input frame
        {
          outputptr = m_inputframe->data[0];
          linesize = m_inputframe->linesize[0];
        }

        FrameToBoblight(outputptr, linesize, boblight);

        if (m_dpy)
        {
          XPutImage(m_dpy, m_window, m_gc, m_xim, 0, 0, 0, 0, g_flagmanager.m_width, g_flagmanager.m_height);
          XSync(m_dpy, False);
        }

        //send rgb values to boblightd
        if (!boblight_sendrgb(boblight, g_flagmanager.m_sync, NULL))
        {
          m_error = boblight_geterror(boblight);
          av_free_packet(&pkt);
          return; //recoverable error
        }
      }
    }

    av_free_packet(&pkt);
  }
}

bool CVideoGrabber::CheckSignal()
{
  if (m_fd == -1) //if we're not checking the signal just return true
    return true;

  struct v4l2_input input = {};
  
	if (ioctl(m_fd, VIDIOC_G_INPUT, &input.index) == -1)
    throw g_flagmanager.m_device + ":" + string(strerror(errno));
	if (ioctl(m_fd, VIDIOC_ENUMINPUT, &input) == -1)
	  throw g_flagmanager.m_device + ":" + string(strerror(errno));
  
	return (!(input.status & V4L2_IN_ST_NO_SIGNAL));
}

void CVideoGrabber::FrameToBoblight(uint8_t* outputptr, int linesize, void* boblight)
{
  //read out pixels and hand them to libboblight
  uint8_t* buffptr;
  for (int y = 0; y < g_flagmanager.m_height; y++)
  {
    buffptr = outputptr + linesize * y;
    for (int x = 0; x < g_flagmanager.m_width; x++)
    {
      int rgb[3];
      rgb[2] = *(buffptr++);
      rgb[1] = *(buffptr++);
      rgb[0] = *(buffptr++);

      boblight_addpixelxy(boblight, x, y, rgb);

      if (m_dpy)
      {
        int pixel;
        pixel  = (rgb[0] & 0xFF) << 16;
        pixel |= (rgb[1] & 0xFF) << 8;
        pixel |=  rgb[2] & 0xFF;

        //I'll probably get the annual inefficiency award for this
        XPutPixel(m_xim, x, y, pixel);
      }
    }
  }
}

void CVideoGrabber::Cleanup()
{
  if (m_dpy)
  {
    XDestroyImage(m_xim);
    XDestroyWindow(m_dpy, m_window);
    XFreeGC(m_dpy, m_gc);
    XCloseDisplay(m_dpy);
    m_dpy = NULL;
  }

  if (m_framebuffer)
  {
    av_free(m_framebuffer);
    m_framebuffer = NULL;
  }

  if (m_sws)
  {
    sws_freeContext(m_sws);
    m_sws = NULL;
  }

  if (m_inputframe)
  {
    av_free(m_inputframe);
    m_inputframe = NULL;
  }

  if (m_outputframe)
  {
    av_free(m_outputframe);
    m_outputframe = NULL;
  }

  if (m_codeccontext)
  {
    avcodec_close(m_codeccontext);
    m_codeccontext = NULL;
  }

  if (m_formatcontext)
  {
    av_close_input_file(m_formatcontext);
    m_formatcontext = NULL;
  }

  if (m_fd != -1)
  {
    close(m_fd);
    m_fd = -1;
  }
}
