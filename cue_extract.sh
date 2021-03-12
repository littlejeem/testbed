#!/usr/env/bin bash
#
# a script to convert find folders with only one .flac file and use the accomapanying .cue file to create the individual flac items
#
enotify "script started"
cd BLAHBLAH || exit
#
test=${find -name "*.flac" | wc -l}
if [[ "$test" -ne 1 ]]; then
  enotify "no flac or multiple flacs found in folder"
else
  candidate=${find -name "*.flac"}
  if [[ grep -Fxq "$FILENAME" log.file ]]; then
    enotify "Album already extracted, exiting"
  else
    enotify "Extracting tracks"
    /home/pi/bin/standalone_scripts/cuesplit.sh
    enotify "logging extraction"
    echo $candidate > log.file
  fi
fi
enotify "script complete"
