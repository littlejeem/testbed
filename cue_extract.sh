#!/usr/bin/env bash
#
# a script to convert find folders with only one .flac file and use the accomapanying .cue file to create the individual flac items
#
#+--------------------------------------+
#+---"Exit Codes & Logging Verbosity"---+
#+--------------------------------------+
# pick from 64 - 113 (https://tldp.org/LDP/abs/html/exitcodes.html#FTN.AEN23647)
# exit 0 = Success
# exit 64 = Variable Error
# exit 65 = Sourcing file/folder error
# exit 66 = Processing Error
# exit 67 = Required Program Missing
#
#verbosity levels
#silent_lvl=0
#crt_lvl=1
#err_lvl=2
#wrn_lvl=3
#ntf_lvl=4
#inf_lvl=5
#dbg_lvl=6
#
#
#+---------------------------+
#+---Set Version & Logging---+
#+---------------------------+
version="0.1"
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
scriptlong="cue_extract.sh" # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)
logdir="/mnt/usbstorage/download/complete/transmission/LidarrMusic"
#set default logging level
verbosity=2
lidarr="/mnt/usbstorage/download/complete/transmission/LidarrMusic"
#
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
source $HOME/bin/standalone_scripts/helper_script.sh
#
#
#+----------------------+
#+---Define functions---+
#+----------------------+
check_folders () {
  array_count=${#names[@]} #counts the number of elements in the array and assigns to the variable names
  echo "$array_count folders found"
  echo "Setting destination folder"
  for (( i=0; i<$array_count; i++)); do #basically says while the count (starting from 0) is less than the value in names do the next bit
    echo "${names[$i]}" ;
    if [[ -d "${names[$i]}" ]]; then
#      cd $i || echo "directory $i unavailiable"
      cd "${names[$i]}"
      test_flac_nums=$(find -name "*.flac" | wc -l)
      if [ "$(find . -maxdepth 1 -type f -iname \*.cue)" ] && [ "$test_flac_nums" == "1" ]; then
        echo "folder structure as expected, 1 .flac and 1 .cue, checking for previous split"
        candidate=$(find -name "*.flac")
        if grep -Fxq "$candidate" "$logdir"/cuesplit.log; then #0 if it is in file, 1 if it isn't
          echo "${names[$i]} album already extracted"
        else
          echo "Extracting tracks from $candidate in ${names[$i]}"
          echo "would now call cuesplit"
          #/home/pi/bin/standalone_scripts/cuesplit.sh
          echo "extraction complete"
          if [[ $reply -ne 0 ]]; then
            echo "something reported as wrong during exit from cuesplit"
          else
            echo $candidate >> "$logdir"/cuesplit.log
          fi
        fi
      else
        echo "folder ${names[$i]}, didnt' meet criteria "
      fi
    else
      echo "input error; array element $i ${names[$i]}, doesn't exist, check and try again"
#      exit 65
    fi
  done
}
#
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+------------------------+
#+--- Define Functions ---+
#+------------------------+
helpFunction () {
   echo ""
   echo "Usage: $0"
   echo "Usage: $0 -vaG selects various artist source, autograb folder, debug level loging"
   echo -e "\t Running the script with no flags causes failure, either -m or -v must be set"
   echo -e "\t-m Use this flag to specify a single artist multi-disc"
   echo -e "\t-v Use this flag to specify a various artist multi-disc"
   echo -e "\t-a Use this flag to tell the script to auto-combine all folders in rip_flac, eg. -a, can be combined with -m or -v to become -ma"
   echo -e "\t-n Use this flag to have the script prompt you for folders to include from rip_flac for combining, eg. -n, can be combined with -m or -v to become -nm"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 1 # Exit script after printing help
}
#
#
#+-----------------+
#+---Main Script---+
#+-----------------+
logdir="/home/pi/bin/script_logs"
#lidarr_folder="/mnt/usbstorage/download/complete/transmission/LidarrMusic"
lidarr_folder="/mnt/usbstorage/download/testbed"
source $HOME/bin/standalone_scripts/helper_script.sh
shopt -s nullglob
echo "Grabbing contents of lidarr dir $lidarr_folder into array"
names=("$lidarr_folder"/*)
check_folders
enotify "script complete"
exit 0
