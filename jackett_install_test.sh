#!/usr/bin/env bash
#
# taken from here https://www.htpcguides.com/install-jackett-ubuntu-15-x-for-custom-torrents-in-sonarr/
#
#+--------------------+
#+---CHECK FOR SUDO---+
#+--------------------+
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi
#
#
#+-------------------+
#+---Source helper---+
#+-------------------+
source ./helper_script3.sh
#
#
#+------------------+
#+---Setup script---+
#+------------------+
username=pi #name of the system user doing the backup
log_folder="/home/$username/bin/logs"
SCRIPT_LOG="/home/$username/bin/logs/jackett_install.log"
sudo -u $username mkdir -p $log_folder
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
#SCRIPTENTRY
#DEBUG "$SCRIPT_LOG"
#DEBUG "$username"
stamp=$(Timestamp)
PATH=/sbin:/bin:/usr/bin:/home/$username
#DEBUG "$PATH"
#
#
cd /opt
#target https://github.com/Jackett/Jackett/releases/download/v0.16.1724/Jackett.Binaries.LinuxAMDx64.tar.gz
#INFO "Getting Jackett version"
jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}')
#DEBUG "jackett version captured is: $jackettver"
#DEBUG "downloading $jackettver"
sudo -u $username wget -q https://github.com/Jackett/Jackett/releases/download/$jackettver/Jackett.Binaries.LinuxAMDx64.tar.gz
if [ $? -ne 0 ]; then
  #ERROR "wget failed, exiting"
  exit 1
fi
#
#
if [ -f "/home/pi/.config/Jackett/ServerConfig.json" ]; then
  #INFO "backing up config file"
  sudo -u $username cp ~/.config/Jackett/ServerConfig.json ~/ServerConfig.json
  #DEBUG "ServerConfig bckup created."
fi
#
#
if [ -f "/etc/systemd/system/jackett.service" ]; then
  #INFO "jackett service detected"
  #INFO "Stopping jackett service"
  systemctl stop jackett.service
  if [ $? -ne 0 ]; then
    #ERROR "stopping service failed"
    exit 1
  fi
else
sudo -u $username cat > /etc/systemd/system/jackett.service << EOF
  [Unit]
  Description=Jackett Daemon
  After=network.target

  [Service]
  SyslogIdentifier=jackett
  Restart=always
  RestartSec=5
  Type=simple
  User=$username
  Group=$username
  WorkingDirectory=/opt/Jackett
  ExecStart=/opt/Jackett/jackett --NoRestart
  TimeoutStopSec=20

  [Install]
  WantedBy=multi-user.target
EOF
fi
#
if [ -d "Jackett" ]; then
  #DEBUG "previous install detected, backing up"
  sudo -u $username mv Jackett Jackett_$stamp
  if [ $? -ne 0 ]; then
    #ERROR "backup creation failed"
    exit 1
  else
    #DEBUG "backup created"
  fi
else
  #DEBUG "No previous install detected"
fi
#
#
#INFO "Extracting .tar ..."
tar -xvf Jackett.tar
if [ $? -ne 0 ]; then
  #ERROR "...extracting .tar failed"
  exit 1
else
  #DEBUG "...extracted .tar"
fi
#
#
chown -R $username:$username
#
#
#INFO "Starting jackett service"
systemctl start jackett.service
if [ $? -ne 0 ]; then
  #ERROR "failed to start jackett service"
  exit 1
else
  #DEBUG "Service Started"
fi
#
#
#SCRIPTEXIT
