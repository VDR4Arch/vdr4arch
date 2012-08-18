#!/bin/bash
#Unset previous timer
echo '0' > /sys/class/rtc/rtc0/wakealarm

#Set new timer 5mins before recording starts
echo $(($1 - 300 )) > /sys/class/rtc/rtc0/wakealarm

#Initiate shutdown
/sbin/halt
