dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(boblight, 2.0)

AM_INIT_AUTOMAKE(AC_PACKAGE_NAME, AC_PACKAGE_VERSION)
AC_CONFIG_HEADERS([config.h])
AM_MAINTAINER_MODE

AC_ISC_POSIX
AC_PROG_CXX
AC_PROG_CC
AC_HEADER_STDC

AM_PROG_LIBTOOL

dnl all use this
AC_CHECK_LIB(pthread,[main])
AC_CHECK_LIB(rt,[main])
AC_CHECK_LIB(m,[main])
AC_CHECK_LIB(dl,[main])
AC_CHECK_DECL([clock_gettime], AC_DEFINE([HAVE_CLOCK_GETTIME], [1], [ ]), [], [[#include <time.h>]])

dnl boblightd
AC_ARG_WITH([portaudio], [AS_HELP_STRING([--without-portaudio], [Disable portaudio support (no support for sound devices)])], [],
            [with_portaudio=check])
AS_IF([test "x$with_portaudio" = xcheck], [
AC_CHECK_HEADERS([portaudio.h],[],
  [AC_MSG_ERROR([Missing a required header, please install it or disable portaudio support by passing --without-portaudio to configure])])
AC_CHECK_TYPE([PaStreamCallbackTimeInfo],[],
  [AC_MSG_ERROR([boblight requires portaudio v19 header! Please install it or disable portaudio by passing --without-portaudio to configure])], [[#include <portaudio.h>]])
AC_CHECK_LIB(portaudio,[main],AC_DEFINE([HAVE_LIBPORTAUDIO], [1], [ ]),
  [AC_MSG_ERROR([Missing a required library, please install it or disable it by passing --without-portaudio to configure])])
])
AM_CONDITIONAL(HAVE_PORTAUDIO, [test "x$with_portaudio" = xcheck])

AC_ARG_WITH([libusb], [AS_HELP_STRING([--without-libusb], [Disable libusb support (no support for iBeLight)])], [],
            [with_libusb=check])
AS_IF([test "x$with_libusb" = xcheck], [
AC_CHECK_LIB([usb-1.0],[main],AC_DEFINE([HAVE_LIBUSB], [1], [ ]))
AC_CHECK_LIB([usb-1.0],[libusb_error_name],AC_DEFINE([HAVE_LIBUSB_ERROR_NAME], [1], [ ]))
AC_CHECK_HEADERS([libusb-1.0/libusb.h],[],[AC_MSG_ERROR([Missing a required header, please install it])])
])
AM_CONDITIONAL(HAVE_LIBUSB, [test "x$with_libusb" = xcheck])

AC_ARG_WITH([spi], [AS_HELP_STRING([--without-spi], [Disable spi support (no support for LPD8806)])], [],
            [with_spi=check])
AS_IF([test "x$with_spi" = xcheck],
[AC_CHECK_HEADERS([linux/spi/spidev.h], [with_spi=yes],
  [AC_MSG_WARN([Missing spidev.h, if you want spi support (for LPD8806) please install the linux kernel headers.])])])
AM_CONDITIONAL(HAVE_SPI, [test "x$with_spi" = xyes])

dnl boblight-X11
AC_ARG_WITH([x11], [AS_HELP_STRING([--without-x11], [Disable x11 support])], [],
            [with_x11=check])

errormsgh="Missing a required header, please install it or disable X11 support by passing --without-x11 to configure"
errormsgl="Missing a required library, please install it or disable X11 support by passing --without-x11 to configure"
AS_IF([test "x$with_x11" = xcheck], [
AC_CHECK_LIB(X11      ,[main],AC_DEFINE([HAVE_LIBX11],       [1], [ ]),
  [AC_MSG_ERROR([$errormsgl])])
AC_CHECK_LIB(Xrender  ,[main],AC_DEFINE([HAVE_LIBXRENDER],   [1], [ ]),
  [AC_MSG_ERROR([$errormsgl])])
AC_CHECK_LIB(Xext     ,[main],AC_DEFINE([HAVE_LIBXRENDER],   [1], [ ]),
  [AC_MSG_ERROR([$errormsgl])])
AC_CHECK_HEADERS([X11/Xlib.h X11/Xutil.h],,
  [AC_MSG_ERROR([$errormsgh])])
AC_CHECK_HEADERS([X11/extensions/Xrender.h X11/extensions/XShm.h],,
  [AC_MSG_ERROR([$errormsgh])], [#include <X11/Xlib.h>])
])
AM_CONDITIONAL(HAVE_X11, [test "x$with_x11" = xcheck])

AC_ARG_WITH([opengl], [AS_HELP_STRING([--without-opengl], [Disable opengl support (boblight-X11 will not be able to capture on vblanks)])], [], [with_opengl=check])
AS_IF([test "x$with_opengl" = xcheck && test "x$with_x11" = xcheck], [
AC_CHECK_LIB(GL, [main], AC_DEFINE([HAVE_LIBGL], [1], [ ]),
  [AC_MSG_ERROR([Missing a required library, please install it or disable opengl by passing --without-opengl to configure])])
AC_CHECK_HEADERS([GL/glx.h], [],
  [AC_MSG_ERROR([Missing a required header, please install it or disable opengl by passing --without-opengl to configure])])
])
AM_CONDITIONAL(HAVE_OPENGL, [test "x$with_opengl" = xcheck && test "x$with_x11" = xcheck])

dnl boblight-v4l
AC_ARG_WITH([ffmpeg], [AS_HELP_STRING([--with-ffmpeg], [Enable ffmpeg support (boblight-v4l will be built)])], [with_ffmpeg=check],
[])

errormsgh="Missing a required header, please install it or disable ffmpeg support by passing --without-ffmpeg to configure"
errormsgl="Missing a required library, please install it or disable ffmpeg support by passing --without-ffmpeg to configure"
AS_IF([test "x$with_ffmpeg" = xcheck], [
AC_CHECK_HEADERS([libavcodec/avcodec.h libavformat/avformat.h libswscale/swscale.h linux/videodev2.h],,AC_MSG_ERROR([$errormsgh]))
AC_CHECK_LIB(avutil   ,[main],AC_DEFINE([HAVE_LIBAVUTIL],    [1], [ ]),AC_MSG_ERROR([$errormsgl])) 
AC_CHECK_LIB(avcodec  ,[main],AC_DEFINE([HAVE_LIBAVCODEC],   [1], [ ]),AC_MSG_ERROR([$errormsgl]))
AC_CHECK_LIB(avformat ,[main],AC_DEFINE([HAVE_LIBAVFORMAT],  [1], [ ]),AC_MSG_ERROR([$errormsgl]), [-lavcodec -lavutil])
AC_CHECK_LIB(swscale  ,[main],AC_DEFINE([HAVE_LIBSWSCALE],   [1], [ ]),AC_MSG_ERROR([$errormsgl]), [-lavutil])
AC_CHECK_LIB(avdevice ,[main],AC_DEFINE([HAVE_LIBAVDEVICE],  [1], [ ]),AC_MSG_ERROR([$errormsgl]), [-lavcodec -lavutil -lavformat])
])
AM_CONDITIONAL(HAVE_FFMPEG, [test "x$with_ffmpeg" = xcheck])

dnl ola
AC_ARG_WITH([ola], [AS_HELP_STRING([--with-ola], [Enable ola support])], [with_ola=check],
[])

errormsgh="Missing a required header, please install it or disable ola support by passing --without-ola to configure"
errormsgl="Missing a required library, please install it or disable ola support by passing --without-ola to configure"
AS_IF([test "x$with_ola" = xcheck], [
AC_CHECK_LIB(ola,[main],,AC_MSG_ERROR([$errormsgl]))
AC_CHECK_LIB(olacommon,[main],,AC_MSG_ERROR([$errormsgl]))
AC_CHECK_LIB(protobuf,[main],,AC_MSG_ERROR([$errormsgl]))
AC_DEFINE([HAVE_OLA], [1], [ ])
])
AM_CONDITIONAL(HAVE_OLA, [test "x$with_ola" = xcheck])

AC_OUTPUT([
Makefile
src/Makefile
])

AS_IF([test "x$with_portaudio" != xcheck], [AC_MSG_WARN([--without-portaudio passed, boblightd will not have support for sound devices])])
AS_IF([test "x$with_ola" != xcheck], [AC_MSG_WARN([--with-ola not passed, boblightd will not have support for ola])])
AS_IF([test "x$with_ffmpeg" != xcheck], [AC_MSG_WARN([--with-ffmpeg not passed, boblight-v4l will not be built (if you don't plan to use boblight-v4l this is ok!)])])
AS_IF([test "x$with_opengl" != xcheck], [AC_MSG_WARN([--without-opengl passed, boblight-X11 will not be able to capture on vblanks])])
AS_IF([test "x$with_x11" != xcheck], [AC_MSG_WARN([--without-x11 passed, boblight-X11 and boblight-v4l will not be built])])

