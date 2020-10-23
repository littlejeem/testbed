#!/usr/bin/env bash
#
# taken from here https://www.htpcguides.com/install-jackett-ubuntu-15-x-for-custom-torrents-in-sonarr/
#
#+-------------------+
#+---Source helper---+
#+-------------------+
source ./helper_script.sh
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
SCRIPTENTRY
SCRIPT_LOG="/home/pi/bin/logs/jackett_install.log"
stamp=$(Timestamp)
#
#
cd /opt
#target https://github.com/Jackett/Jackett/releases/download/v0.16.1724/Jackett.Binaries.LinuxAMDx64.tar.gz
INFO "Getting Jackett version"
jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}')
INFO "jackett version captured is: $jackettver"
INFO "downloading $jackettver"
wget -q https://github.com/Jackett/Jackett/releases/download/$jackettver/Jackett.Binaries.LinuxAMDx64.tar.gz
if [ $? -ne 0 ]; then
  DEBUG "wget failed, exiting"
  exit 1
fi
#
#
if [ $? -ne 0 ]; then
  DEBUG "backup creation failed"
  exit 1
fi
#
#
if [ -f "/home/pi/.config/Jackett/ServerConfig.json" ]; then
  cp ~/.config/Jackett/ServerConfig.json ~/ServerConfig.json
  INFO "ServerConfig bckup created."
fi
#
#
INFO "Stopping jackett service"
systemctl stop jackett.service
#
if [ -d "Jackett" ]; then
  INFO "previous install detected, backing up"
  mv Jackett Jackett_$stamp
  if [ $? -ne 0 ]; then
    DEBUG "backup creation failed"
    exit 1
  else
    INFO "backup created"
  fi
else
  INFO "No previous install detected"
fi
#
#
INFO "Extracting .tar ..."
tar -xvf Jackett.tar
if [ $? -ne 0 ]; then
  DEBUG "...extracting .tar failed"
  exit 1
else
  INFO "...extracted .tar"
fi
#
#
INFO "Starting jackett service"
systemctl start jackett.service
if [ $? -ne 0 ]; then
  DEBUG ""
  exit 1
else
  INFO "Service Started"
fi
#
#
SCRIPTEXIT
