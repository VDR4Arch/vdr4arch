## Process this file with automake to produce Makefile.in

AM_CPPFLAGS = 

AM_CFLAGS =\
	 -Wall \
	 -g

bin_PROGRAMS = boblightd \
	boblight-constant
        

if HAVE_X11
bin_PROGRAMS += boblight-X11

if HAVE_FFMPEG
bin_PROGRAMS += boblight-v4l
endif

endif

boblight_v4l_SOURCES = \
	clients/boblight-v4l/boblight-v4l.cpp \
	clients/boblight-v4l/flagmanager-v4l.cpp \
	util/misc.cpp \
	clients/flagmanager.cpp \
	clients/boblight-v4l/videograbber.cpp \
        util/daemonize.cpp

boblight_v4l_LDFLAGS = -lavutil -lavcodec -lavformat -lswscale -lavdevice -lX11

boblight_constant_SOURCES = \
	clients/boblight-constant/boblight-constant.cpp \
	clients/flagmanager.cpp \
	clients/boblight-constant/flagmanager-constant.cpp \
	util/misc.cpp \
        util/daemonize.cpp

boblight_X11_SOURCES = \
	clients/boblight-X11/boblight-X11.cpp \
	util/timer.cpp \
	util/condition.cpp \
	util/mutex.cpp \
	util/thread.cpp \
	util/misc.cpp \
        util/timeutils.cpp \
        util/daemonize.cpp \
	clients/boblight-X11/grabber-base.cpp \
	clients/boblight-X11/grabber-xgetimage.cpp \
	clients/boblight-X11/grabber-xrender.cpp \
	clients/boblight-X11/flagmanager-X11.cpp \
	clients/flagmanager.cpp

boblight_X11_LDFLAGS = -lX11 -lXrender -lXext

if HAVE_OPENGL
  boblight_X11_SOURCES += clients/boblight-X11/vblanksignal.cpp
  boblight_X11_LDFLAGS += -lGL
endif

boblightd_SOURCES = \
	util/condition.cpp \
	util/log.cpp \
	util/misc.cpp \
	util/mutex.cpp \
	util/thread.cpp \
	util/timer.cpp \
	util/serialport.cpp \
        util/timeutils.cpp \
	main.cpp \
	util/tcpsocket.cpp \
	util/messagequeue.cpp \
	client.cpp \
	light.cpp \
	configuration.cpp \
	device/device.cpp \
	device/devicepopen.cpp \
	device/devicers232.cpp \
	device/deviceltbl.cpp \
	device/devicedioder.cpp \
	device/deviceambioder.cpp \
        util/signaltimer.cpp \
        util/daemonize.cpp

boblightd_LDFLAGS =

boblightd_LDADD = 

if HAVE_PORTAUDIO
boblightd_SOURCES += device/devicesound.cpp
boblightd_LDFLAGS += -lportaudio
endif

if HAVE_LIBUSB
boblightd_SOURCES += device/deviceibelight.cpp \
	device/devicelightpack.cpp
boblightd_LDFLAGS += -lusb-1.0
endif

if HAVE_OLA
boblightd_SOURCES += device/deviceola.cpp
boblightd_LDFLAGS += -lola -lolacommon -lprotobuf
endif

if HAVE_SPI
boblightd_SOURCES += device/devicespi.cpp
endif

lib_LTLIBRARIES = \
	libboblight.la

libboblight_la_SOURCES = \
	lib/boblight_client.cpp \
	lib/boblight.cpp \
	util/messagequeue.cpp \
	util/misc.cpp \
	util/tcpsocket.cpp

libboblight_la_CPPFLAGS = $(AM_CPPFLAGS)

