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
version="0.6"
#set default logging level
verbosity=4
logdir="/home/pi/bin/script_logs"
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
scriptlong="cue_extract.sh" # imports the name of this script
lockname=${scriptlong::-3} # reduces the name to remove .sh
script_pid=$(echo $$)
lidarr_folder="/mnt/usbstorage/download/complete/transmission/LidarrMusic"
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
        flac_candidate=$(find -name "*.flac")
        cue_candidate=$(find -name "*.cue")
        edebug "flac_candidate recorded as $flac_candidate"
        edebug "cue_candidate recorded as $cue_candidate"
        if grep -Fxq "$flac_candidate" "$logdir"/cuesplit.log; then #0 if it is in file, 1 if it isn't
          enotify "${names[$i]} album already extracted"
        else
          edebug "Extracting tracks from $flac_candidate in ${names[$i]}"
          if [[ $dry_run -eq 1 ]]; then
            edebug "dry-run enabled no cue script called"
          else
            edebug "calling cuesplit"
            if [ -t 0 ]; then #test for tty connection, 0 = connected, else not
              edebug "terminal connection detected, running for connected user"
              /home/pi/bin/standalone_scripts/cuesplit.sh > /dev/null 2>&1 &
              cue_pid=$!
              pid_name=$cue_pid
              edebug "cuesplit PID is: $cue_pid, recorded as PID_name: $pid_name"
              progress_bar
            else
              edebug "No terminal connected, running as system script"
              /home/pi/bin/standalone_scripts/cuesplit.sh
            fi
            if [[ $reply -ne 0 ]]; then
              ewarn "something reported as wrong during exit from cuesplit"
            else
              edebug "extraction complete"
              edebug "recording $flac_candidate as successful extract to $logdir/cuesplit.log"
              echo $flac_candidate >> "$logdir"/cuesplit.log
              if [ $keep_files = "1" ]; then
                edebug "keep source files specified, not deleting"
              else
                edebug "removing .flac source"
                rm "$flac_candidate"
                if [[ $? -ne 0 ]]; then
                  eerror "error removing .flac file"
                  exit 65
                fi
                edebug "removing .cue source"
                rm "$cue_candidate"
                if [[ $? -ne 0 ]]; then
                  eerror "error removing .cue file"
                  exit 65
                fi
              fi
            fi
          fi
        fi
      else
        edebug "folder ${names[$i]}, didnt' meet criteria "
      fi
    else
      eerror "input error; array element $i ${names[$i]}, doesn't exist, check and try again"
      exit 65
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
   echo -e "\t-d Use this flag to specify dry run, no files will be converted, useful in conjunction with -V or -G "
   echo -e "\t-k Override the deletion of source .cue & .flac files"
   echo -e "\t-s Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     eerror "problem removing lock directory"
     exit 65
   fi
   exit 1 # Exit script after printing help
}
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":dksVGh:" opt
do
    case "${opt}" in
      d) dry_run="1"
      enotify "-d specified: dry run initiated";;
      k) keep_files="1"
      enotify "-k specified: keeping source .cue .flac files post extract";;
      s) verbosity=$silent_lvl
      enotify "-s specified: Silent mode";;
      V) verbosity=$inf_lvl
      enotify "-V specified: Verbose mode";;
      G) verbosity=$dbg_lvl
      enotify "-G specified: Debug mode";;
      h) helpFunction;;
      ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
#
#
JAIL_FATAL="${lidarr_folder}"
fatal_missing_var
#+-----------------+
#+---Main Script---+
#+-----------------+
esilent "Script Started"
edebug "Version is $version"
edebug "PID: $script_pid"
shopt -s nullglob
edebug "Grabbing contents of lidarr dir $lidarr_folder into array"
names=("$lidarr_folder"/*)
check_folders
esilent "script complete"
rm -r /tmp/cue_extract
if [[ $? -ne 0 ]]; then
  eerror "removing file"
  exit 65
fi
exit 0
