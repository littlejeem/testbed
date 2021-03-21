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
version="0.3"
#set default logging level
verbosity=2
logdir="/home/pi/bin/script_logs"
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
scriptlong="cue_extract.sh" # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)
#lidarr_folder="/mnt/usbstorage/download/complete/transmission/LidarrMusic"
lidarr_folder="/mnt/usbstorage/download/testbed"
#
#
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
PATH=/sbin:/bin:/usr/bin:/home/jlivin25:/home/jlivin25/.local/bin:/home/jlivin25/bin
source "$HOME"/bin/standalone_scripts/helper_script.sh
#
#
#+----------------------+
#+---Define functions---+
#+----------------------+
check_folders () {
  array_count=${#names[@]} #counts the number of elements in the array and assigns to the variable names
  edebug "$array_count folders found"
  edebug "Setting destination folder"
  for (( i=0; i<$array_count; i++)); do #basically says while the count (starting from 0) is less than the value in names do the next bit
    edebug "${names[$i]}" ;
    if [[ -d "${names[$i]}" ]]; then
      cd "${names[$i]}" || exit 65
      test_flac_nums=$(find -name "*.flac" | wc -l)
      if [ "$(find . -maxdepth 1 -type f -iname \*.cue)" ] && [ "$test_flac_nums" == "1" ]; then
        edebug "folder structure as expected, 1 .flac and 1 .cue, checking for previous split"
        candidate=$(find -name "*.flac")
        if grep -Fxq "$candidate" "$logdir"/cuesplit.log; then #0 if it is in file, 1 if it isn't
          edebug "${names[$i]} album already extracted"
        else
          edebug "Extracting tracks from $candidate in ${names[$i]}"
          if [[ $dry_run -eq 1 ]]; then
            edebug "dry-run enabled no script called"
          else
            edebug "calling cuesplit"
            /home/pi/bin/standalone_scripts/cuesplit.sh
            script_exit
            if [[ $reply -ne 0 ]]; then
              edebug "something reported as wrong during exit from cuesplit"
            else
              edebug "extraction complete"
              edebug "recording $candidate as successful extract to $logdir/cuesplit.log"
              echo $candidate >> "$logdir"/cuesplit.log
            fi
          fi
        fi
      else
        edebug "folder ${names[$i]}, didnt' meet criteria "
      fi
    else
      edebug "input error; array element $i ${names[$i]}, doesn't exist, check and try again"
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
   echo "Usage: $0 -dV selects dry-run with verbose level logging"
   echo -e "\t-d Use this flag to specify dry run, no files will be converted, usefu in conjunction with -V or -G "
   echo -e "\t-s Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 1 # Exit script after printing help
}
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":dsVGh:" opt
do
    case "${opt}" in
      d) dry_run="1"
      edebug "-d specified: dry run initiated";;
      s) verbosity=$silent_lvl
      edebug "-s specified: Silent mode";;
      V) verbosity=$inf_lvl
      edebug "-V specified: Verbose mode";;
      G) verbosity=$dbg_lvl
      edebug "-G specified: Debug mode";;
      h) helpFunction;;
      ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
#
#
#+-----------------+
#+---Main Script---+
#+-----------------+
enotify "Script Started"
#lidarr_folder="/mnt/usbstorage/download/complete/transmission/LidarrMusic"
edebug "Version is $version"
edebug "PID: $script_pid"
shopt -s nullglob
edebug "Grabbing contents of lidarr dir $lidarr_folder into array"
names=("$lidarr_folder"/*)
check_folders
enotify "script complete"
rm -r /tmp/cue_extract
exit 0
