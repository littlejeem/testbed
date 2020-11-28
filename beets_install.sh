#!/usr/bin/env bash
#
assigned_user="jlivin25"
dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#
#+------------------------------------+
#+---"Test for root running script"---+
#+------------------------------------+
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi
#
#
#+------------------------+
#+---"Install main app"---+
#+------------------------+
apt update
apt install python-dev python-pip -y
sudo -u $assigned_user pip install --user beets
#
#
#+----------------------------------------+
#+---"Install dependancies for plugins"---+
#+----------------------------------------+
# chroma
sudo -u $assigned_user pip install pyacoustid
sudo -u $assigned_user pip install gmusicapi
apt install -y libchromaprint-tools
#
#
#+--------------------------------+
#+---"Set up default locations"---+
#+--------------------------------+
# conversion destinations
sudo -u $assigned_user mkdir -p $HOME/Music/Library/alacimports
sudo -u $assigned_user mkdir -p $HOME/Music/Library/flacimports
sudo -u $assigned_user mkdir -p $HOME/Music/Library/PlayUploads
# library file sources
sudo -u $assigned_user mkdir -p $HOME/.config/beets/alac
sudo -u $assigned_user mkdir -p $HOME/.config/beets/flac
sudo -u $assigned_user mkdir -p $HOME/.config/beets/uploads
#
#
#+-------------------------+
#+---"Copy config files"---+
#+-------------------------+
sudo -u $assigned_user cp $dir_name/alac_config.yaml $HOME/.config/beets/alac/
sudo -u $assigned_user cp $dir_name/flac_config.yaml $HOME/.config/beets/flac/
sudo -u $assigned_user cp $dir_name/uploads_config.yaml $HOME/.config/beets/uploads/
#
#
