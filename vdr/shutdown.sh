#!/bin/bash
#Sync back system time to hardware time (Maybe VDR has changed it)
hwclock --systohc --utc

#Unset previous timer
echo '0' > /sys/class/rtc/rtc0/wakealarm

#Set new timer 5mins before recording starts
echo $(($1 - 300 )) > /sys/class/rtc/rtc0/wakealarm

#Initiate shutdown
/sbin/shutdown -h now
