#!/usr/bin/env bash
#
#########################################################################
###    "PUT INFO ABOUT THE SCRIPT, ITS PURPOSE, HOW IT WORKS"         ###
###      "WHERE IT SHOULD BE KEPT, DEPENDANCIES, etc...here"          ###
#########################################################################
#
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
#+----------------------+
#+---"Check for Root"---+
#+----------------------+
#only needed if root privaleges necessary, enable
#if [[ $EUID -ne 0 ]]; then
#    echo "Please run this script with sudo:"
#    echo "sudo $0 $*"
#    exit 66
#fi
#
#
#+-----------------------+
#+---"Set script name"---+
#+-----------------------+
# imports the name of this script
# failure to to set this as lockname will result in check_running failing and 'hung' script
# manually set this if being run as child from another script otherwise will inherit name of calling/parent script
scriptlong=`basename "$0"`
lockname=${scriptlong::-3} # reduces the name to remove .sh
#
#
#+-------------------------------------+
#+---"Source helper script & others"---+
#+-------------------------------------+
source /usr/local/bin/helper_script.sh
source /usr/local/bin/omdb_key
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
#set default logging level, failure to set this will cause a 'unary operator expected' error
#remember at level 3 and lower, only esilent messages show, best to include an override in getopts
verbosity=3
#
version="0.7" #
notify_lock="/tmp/$lockname"
#pushover_title="NAME HERE" #Uncomment if using pushover
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+---------------------+
#+---"Set functions"---+
#+---------------------+
helpFunction () {
   echo ""
   echo "Usage: $0 $scriptlong"
   echo "Usage: $0 $scriptlong -G -r -e -t ## -n "TITLE HERE" -q ## -s -c"
   echo -e "\t Running the script with no flags causes default behaviour with logging level set via 'verbosity' variable"
   echo -e "\t-S Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-r Rip Only: Will cause the script to only rip the disc, not encode"
   echo -e "\t-e Encode Only: Will cause the script to encode to container only, no disc rip"
   echo -e "\t-t Manually provide the title to rip eg. -t 42"
   echo -e "\t-n Manually provide the feature name to lookup eg. -n "BLACK HAWK DOWN", useful for those discs that aren't helpfully named"
   echo -e "\t-q Manually provide the quality to encode in handbrake, eg. -q 21. default value is 19, anything lower than 17 is considered placebo"
   echo -e "\t-s Source delete override: By default the script removes the source files on completion. Selecting this flag will keep the files"
   echo -e "\t-c Temp Override: By default the script removes any temp files on completion. Selecting this flag will keep the files, useful if debugging"
   echo -e "\t-h -H Use this flag for help"
   if [ -d "/tmp/$lockname" ]; then
     edebug "removing lock directory"
     rm -r "/tmp/$lockname"
   else
     edebug "problem removing lock directory"
   fi
   exit 65 # Exit script after printing help
}
#
convert_secs_hr_min () {
  #from here https://stackoverflow.com/questions/12199631/convert-seconds-to-hours-minutes-seconds
  num=$(echo $secs)
  min=0
  hour=0
  if((num>59));then
      ((sec=num%60))
      ((num=num/60))
          if((num>59));then
          ((min=num%60))
          ((num=num/60))
              if((num>23));then
                  ((hour=num%24))
              else
                  ((hour=num))
              fi
          else
              ((min=num))
          fi
      else
      ((sec=num))
  fi
  hour=`seq -w 00 $hour | tail -n 1`
  min=`seq -w 00 $min | tail -n 1`
  sec=`seq -w 00 $sec | tail -n 1`
  printf "$hour:$min"
}
#
clean_main_feature_scan () {
  #we use sed to take all text after (inclusive) "Version: {" from main_feature_scan.json and put it into main_feature_scan_trimmed.json
  #sed -n '/Version: {/,$w main_feature_scan_trimmed.json' main_feature_scan.json
  #we use sed to take all text after (inclusive) "JSON Title Set: {" from main_feature_scan.json and put it into main_feature_scan_trimmed.json
  sed -n '/JSON Title Set: {/,$w main_feature_scan_trimmed.json' main_feature_scan.json
  #now we need to delete the top line left as "JSON Title Set: {"
  sed -i '1d' main_feature_scan_trimmed.json
  #we now  need to insert a spare '{' & a '[' at the start of the file
  sed -i '1s/^/{\n/' main_feature_scan_trimmed.json
  sed -i '1s/^/[\n/' main_feature_scan_trimmed.json
  #and now we need to add ']' to the end of the file
  echo "]" >> main_feature_scan_trimmed.json
  edebug "... main_feature_scan_trimmed.json created"
}
#
#
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":SVGHh:re:t:q:sc" opt
do
    case "${opt}" in
        S) verbosity=$silent_lvl
        edebug "-S specified: Silent mode";;
        V) verbosity=$inf_lvl
        edebug "-V specified: Verbose mode";;
        G) verbosity=$dbg_lvl
        edebug "-G specified: Debug mode";;
        r) rip_only=1
        edebug "rip_only selected, only ripping not encoding";;
        e) encode_only=1
        edebug "encode_only selected, only encoding not ripping";;
        t) title_override=${OPTARG}
        edebug "title_override chosen, using supplied track of: $title_override";;
        n) name_override=${OPTARG}
        edebug "name override given, using supplied title name of: $title_override";;
        q) quality_override=${OPTARG}
        quality=$quality_override
        edebug "quality_override detected using quality $quality";;
        s) source_clean_override=1
        edebug "source clean override selected, keeping SOURCE files";;
        c) temp_clean_override=1
        edebug "temp clean override selected, keeping TEMP files";;
        H) helpFunction;;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
#
#
#+----------------------+
#+---"Script Started"---+
#+----------------------+
# At this point the script is set up and all necessary conditions.
esilent "$lockname started"
#
#+--------------------------------------+
#+---"Display some info about script"---+
#+--------------------------------------+
edebug "Version of $scriptlong is: $version"
edebug "PID is $script_pid"
#
#
#+---------------------+
#+---"Set up script"---+
#+---------------------+
#Get environmental info
edebug "INVOCATION_ID is set as: $INVOCATION_ID"
edebug "EUID is set as: $EUID"
edebug "PATH is: $PATH"
#
###############################
### Move to a settings file ###
###############################
  dev_drive="/dev/sr0"
  edebug "source media drive us $dev_drive"
  drive_num=${dev_drive: -1}
  edebug "drive_num: $drive_num"
  makemkv_drive="disc:$drive_num"
  edebug "makemkv drive is: $makemkv_drive"
  working_dir="/home/jlivin25/Videos"
  edebug "working directory is: $working_dir"
  category="blurays"
  edebug "category is: $category"
  rip_dest="Rips"
  edebug "destination for Rips is: $rip_dest"
  encode_dest="Encodes"
  edebug "destination for Encodes is: $encode_dest"
#
#+----------------------------+
#+---"Main Script Contents"---+
#+----------------------------+
#Check Enough Space Remaining, will only work once variables moved to config script
space_left=$(df $working_dir | awk '/[0-9]%/{print $(NF-2)}')
edebug "space left in working directory is: $space_left"
if [ "$space_left" -le 65000000 ]; then
  eerror "not enough space to run rip & encode, terminating"
  exit 66
else
  edebug "Free space check passed, continuing"
fi
#
#Configure Disc Ripping
if [[ -z $quality_override ]]; then
  quality="19.0"
fi
edebug "quality selected is $quality"
#
#Get and use hard coded name of media
bluray_name=$(blkid -o value -s LABEL "$dev_drive")
bluray_name=${bluray_name// /_}
edebug "optical disc bluray name is: $bluray_name"
#
#
#Perhpas build up a list of known FOOBAR'd disc labels such as 'LOGICAL_VOLUME, DISC1 etc?'
#Get name of media according to syslogs, this will only work if this script is being used automatically via UDEV / SYSTEMD otherwise name likely to me buried in older logs
bluray_sys_name=$(grep "UDF-fs: INFO Mounting volume" /var/log/syslog | tail -1 | cut -d ':' -f 5 | cut -d ' ' -f 5)
#its empty try syslog.1
if [[ -z $bluray_sys_name ]]; then
  bluray_sys_name=$(grep "UDF-fs: INFO Mounting volume" /var/log/syslog.1 | tail -1 | cut -d ':' -f 5 | cut -d ' ' -f 5)
fi
#set what to do if result is found
if [[ ! -z $bluray_sys_name ]]; then
  bluray_sys_name=${bluray_sys_name:1:-2}
  edebug "bluray_sys_name found, using: $bluray_sys_name"
  bluray_name=$bluray_sys_name
fi
# create the temp dir, failure to set this will error out handrake parsing info
mkdir -p "$working_dir/temp/$bluray_name"

#+-------------------------+
#+---"Setup Ripping"---+
#+-------------------------+
#set output location for makemkv, not in "encode_only as is used in handrake as $source_loc"
if [[ ! -z "$working_dir" ]] && [[ ! -z "$rip_dest" ]] && [[ ! -z "$category" ]] && [[ ! -z "$bluray_name" ]]; then
  edebug "valid Rips (source) directory, creating"
  makemkv_out_loc="$working_dir/$rip_dest/$category/$bluray_name"
  mkdir -p "$makemkv_out_loc"
else
  eerror "error with necessary variables to create Rips(source files) location"
  exit 65
fi
edebug "Rip / Source files will be at: $makemkv_out_loc"
#
#
#+-------------------------+
#+---"Carry Out Ripping"---+
#+-------------------------+
if [[ ! -z "$encode_only" ]]; then
  #Set up functions to get information for progress bar
  get_max_progress () {
    tail -n 1 "$working_dir/temp/$bluray_name/$bluray_name.log" | cut -d ',' -f 3
  }
  #
  get_total_progress () {
    tail -n 1 "$working_dir/temp/$bluray_name/$bluray_name.log" | cut -d ',' -f 2
  }
  edebug "${colpup}makemakv running...${colrst}"
  unit_of_measure="cycles"
  makemkvcon backup --decrypt --progress="$working_dir/temp/$bluray_name/$bluray_name.log" -r "$makemkv_drive" "$makemkv_out_loc" > /dev/null 2>&1 &
  makemkv_pid=$!
  pid_name=$makemkv_pid
  sleep 15s # to give time for drive to wind up and files to be created
  progress_bar2_init
  if [ $? -eq 0 ]; then
    edebug "...makemkvcon bluray rip completed successfully"
  else
    eerror "makemkv producded an error, code: $?"
    exit 66
  fi
fi
#
#
#+----------------------+
#+---"Setup Encoding"---+
#+----------------------+
#
options="--json --no-dvdna"
source_loc="$makemkv_out_loc" #this should match the makemkv output location
output_options="-f mkv"
video_options="-e x264 --encoder-preset medium --encoder-tune film --encoder-profile high --encoder-level 4.1 -q $quality -2"
picture_options="--crop 0:0:0:0 --loose-anamorphic --keep-display-aspect --modulus 2"
filter_options="--decomb"
subtitle_options="-N eng -F scan"
#
#make the working directory if not already existing
#this step is vital, otherwise the files below are created whereever the script is run from and will fail
cd "$working_dir/temp/$bluray_name" || { edebug "Failure changing to working directory temp"; exit 65; }
#
#Grap all titles from source
HandBrakeCLI --json -i $source_loc -t 0 --main-feature &> all_titles_scan.json
#search file for identified main feature
auto_found_main_feature=$(grep -w "Found main feature title" all_titles_scan.json)
if [[ -z $auto_found_main_feature ]]; then
  eerror "Something went wrong with auto_found_main_feature"
  exit 66
fi
edebug "auto_found_main_feature is: $auto_found_main_feature"
#we cut unwanted "Found main feature title " text from the variable
auto_found_main_feature=${auto_found_main_feature:25}
edebug "auto_found_main_feature cut to: $auto_found_main_feature"


#NOW CREATE main feature_scan
edebug "creating main_feature_scan.json ..."
#do X if no title over-ride, else use the title over-ride
if [[ -z $title_override ]]; then
  HandBrakeCLI --json -i $source_loc -t $auto_found_main_feature --scan 1> main_feature_scan.json 2> /dev/null
else
  HandBrakeCLI --json -i $source_loc -t $title_override --scan 1> main_feature_scan.json 2> /dev/null
fi


#CLEAN FILE FOR JQ
clean_main_feature_scan
#SEARCH FOR FEATURE NAME VIA JQ
if [[ -z $name_override ]]; then
  feature_name=$(jq --raw-output '.[].TitleList[].Name' main_feature_scan_trimmed.json | head -n 1 | sed -e "s/ /_/g")
else
  feature_name="$name_override"
fi
edebug "feature name is: $feature_name"
#SEARCH ONLINE FOR FEATURE NAME
omdb_title_result=$(curl -sX GET --header "Accept: */*" "http://www.omdbapi.com/?t=${feature_name}&apikey=${omdb_apikey}")
#IF ONLINE SEARCH SUCCEEDS DO EXTRA.
#{"Response":"False","Error":"Incorrect IMDb ID."}
if [[ "$omdb_title_result" = *'"Title":"'* ]]; then
  edebug "omdb matching info is: $omdb_title_result"
  omdb_title_name_result=$(echo $omdb_title_result | jq --raw-output '.Title')
  edebug "omdb title name is: $omdb_title_name_result"
  omdb_year_result=$(echo $omdb_title_result | jq --raw-output '.Year')
  edebug "omdb year is: $omdb_year_result"
  edebug "Getting runtime info..."
  #extract runtime from mass omdb result
  omdb_runtime_result=$(echo $omdb_title_result | jq --raw-output '.Runtime')
  #strip out 'min'
  omdb_runtime_result=${omdb_runtime_result%????}
  edebug "omdb runtime is (mins): $omdb_runtime_result ..."
  #convert to 'secs'
  secs=$((omdb_runtime_result*60))
  edebug "...equal to (secs): $secs"
  #use function to convert seconds to desired runtime format
  edebug "converting to runtime format..."
  runtime_check=$(convert_secs_hr_min)
  edebug "...runtime is: $runtime_check (hh:mm). Checking titles containing this runtime"
  #check all_titles_scan.json for titles containing runtime
  title1=$(grep -B 2 $runtime_check all_titles_scan.json | awk 'NR==1' | cut -d ' ' -f 5)
  title2=$(grep -B 2 $runtime_check all_titles_scan.json | awk 'NR==5' | cut -d ' ' -f 5)
  #strip down to just titles value (track), not time!)
  if [[ ! -z "$title1" ]]; then
    edebug "Title(s) matching runtime is: $title1"
  fi
  if [[ ! -z "$title2" ]]; then
    edebug "Title(s) matching runtime is: $title2"
  fi
elif [[ "$omdb_title_result" = *'"Error":"No API key provided."'* ]]; then
  edebug "online search failed not doing extra stuff"
elif [[ "$omdb_title_result" = *'"Error":"Incorrect IMDb ID."'* ]]; then
  edebug "omdb search ran but no matching result could be found"
elif [[ "$omdb_title_result" = *'"Error":"Movie not found!"'* ]]; then
  edebug "omdb search ran but no matching result could be found"
else
  edebug "Some other error occured, dumping omdb_title_result"
  edebug "omdb_title_result is: $omdb_title_result"
fi


  #TEST RESULTS TO SEE WHICH TO CHOOSE AND IF DIFFERENT TO OUT AUTO FIND TITLE WE NEED TO RECREATE main_feature_scan.json BEFORE AUDIO CHECK
if [[ -z "$title1" && -z "$title2" ]]; then
  edebug "no online data to use, so using local data"
elif [[ "$title1" != "$auto_found_main_feature" && "$title2" != "$auto_found_main_feature" ]]; then
  edebug "online check resulted in titles $title1 & $title2, matching online runtime but NOT, handbrakes automatically found main feature: $auto_found_main_feature, using title2"
  #we choose title 2 when there are 2 detected as this better than 50% right most of the time imo.
  mv main_feature_scan.json main_feature_scan.json.original
  auto_found_main_feature=$(echo $title2)
  HandBrakeCLI --json -i $source_loc -t $auto_found_main_feature --scan 1> main_feature_scan.json 2> /dev/null
  clean_main_feature_scan
elif [[ "$title1" == "$auto_found_main_feature" && "$title2" == "$auto_found_main_feature" ]]; then
  edebug "online check resulted in both titles, matching handbrakes automatically found main feature: $auto_found_main_feature. Using title2"
  #we choose title 2 when there are 2 detected as this better than 50% right most of the time imo.
  mv main_feature_scan.json main_feature_scan.json.original
  auto_found_main_feature=$(echo $title2)
  HandBrakeCLI --json -i $source_loc -t $auto_found_main_feature --scan 1> main_feature_scan.json 2> /dev/null
  clean_main_feature_scan
elif [[ "$title1" != "$auto_found_main_feature" && "$title2" == "$auto_found_main_feature" ]]; then
  edebug "online check resulted in title2, matching handbrakes automatically found main feature $auto_found_main_feature, using title2"
  mv main_feature_scan.json main_feature_scan.json.original
  auto_found_main_feature=$(echo $title2)
  HandBrakeCLI --json -i $source_loc -t $auto_found_main_feature --scan 1> main_feature_scan.json 2> /dev/null
  clean_main_feature_scan
elif [[ "$title1" == "$auto_found_main_feature" && "$title2" != "$auto_found_main_feature" ]]; then
  #then title 1 is set but if $title2 is valid $title2 is set
  edebug "${red_highlight} online check resulted in only title1 matching handbrakes automatically found main feature, using"
fi
#
#EXTRACT AUDIO TRACKS FROM $main_feature_scan_trimmed into parsed_audio_tracks
jq '.[].TitleList[].AudioList[].Description' main_feature_scan_trimmed.json > parsed_audio_tracks
#
#+----------------------------------+
#+---"Determine Availiable Audio"---+
#+----------------------------------+
#First we search the file for the line number of our preferred source because line number = track number of the audio
#these tests produce boolean returns
#First lets test for uncompressed LPCM
BD_lpcm=$(grep -hn "BD LPCM" parsed_audio_tracks | cut -c1)
[[ ! -z "$BD_lpcm" ]] && edebug "BD LPCM detected, track: $BD_lpcm" || edebug "BD LPCM not detected"
#Check for True_HD
True_HD=$(grep -hn "TrueHD" parsed_audio_tracks | cut -c1)
[[ ! -z "$True_HD" ]] && edebug "True HD detected, track: $True_HD" || edebug "True_HD not detected"
#Now lets test for DTS-HD
Dts_hd=$(grep -hn "DTS-HD" parsed_audio_tracks)
Dts_hd=$(echo $Dts_hd | cut -c1)
[[ ! -z "$Dts_hd" ]] && edebug "DTS-HD detected, track: $Dts_hd" || edebug "DTS-HD not detected"
#Now lets test for DTS
Dts=$(grep -hn "(DTS)" parsed_audio_tracks)
Dts=$(echo $Dts | cut -c1)
[[ ! -z "$Dts" ]] && edebug "DTS detected, track: $Dts" || edebug "DTS not detected"
#Finally lets test for AAC
Ac3=$(grep -hn "AC3" parsed_audio_tracks)
Ac3=$(echo $Ac3 | cut -c1)
[[ ! -z "$Ac3" ]] && edebug "AC3 detected, track: $Ac3" || edebug "AC3 not detected"
#
#
#+------------------------------+
#+---"Determine 'Best' Audio"---+
#+------------------------------+
#Now we make some decisons about audio choices
# if its present always prefer: TrueHD, if not; DTS-HD, if not; BD LPCM; if not DTS. if none of the above then AC3,
if [[ ! -z "$True_HD" ]]; then #true = TrueHD
  selected_audio_track=$(echo $True_HD)
  edebug "Selecting True_HD audio, track $True_HD"
elif [[ ! -z "$True_HD" ]] && [[ ! -z "$Dts_hd" ]]; then #true false = TrueHD
  selected_audio_track=$(echo $True_HD)
  edebug "Selecting True_HD audio, track $True_HD"
elif [[ -z "$True_HD" ]] && [[ ! -z "$Dts_hd" ]]; then #false true = DTS-HD
  selected_audio_track=$(echo $Dts_hd)
  edebug "Selecting DTS-HD audio, track $Dts_hd"
elif [[ ! -z "$BD_lpcm" ]] && [[ -z "$True_HD" ]] && [[ -z "$Dts_hd" ]]; then #true false false = BD LPCM
  selected_audio_track=$(echo $BD_lpcm)
  edebug "Selecting BD LPCM audio, track $BD_lpcm"
elif [[ -z "$True_HD" ]] && [[ -z "$Dts_hd" ]] && [[ -z "$BD_lpcm" ]] && [[ ! -z "$Dts" ]]; then #false false false true = DTS
  selected_audio_track=$(echo $Dts)
  edebug "Selecting DTS audio, track $Dts"
elif [[ -z "$True_HD" ]] && [[ -z "$Dts_hd" ]] && [[ -z "$BD_lpcm" ]] && [[ -z "$Dts" ]]; then #false false false false = AC3 (default)
  selected_audio_track=1
  edebug "no matches for audio types, defaulting to track 1"
fi
#
#
#+--------------------------+
#+---"Carry Out Encoding"---+
#+--------------------------+
#insert the audio selection into the audio_options variable
if [[ ! -z $BD_lpcm ]]; then
  audio_options="-a $selected_audio_track -E flac24 --mixdown 5point1"
else
  audio_options="-a $selected_audio_track -E copy --audio-copy-mask dtshd,truehd,dts,flac"
fi
edebug "audio options passed to HandBrakeCLI are: $audio_options"
#use our found main feature from the work at the top...
source_options="-t $auto_find_main_feature"
#...but override it if override is set
if [[ $title_override != "" ]]; then
  source_options=-"t $title_override"
  edebug "title override selected, using: $title_override"
fi
#display what the result is
edebug "source options are: $source_options"
#lets use our fancy name IF found online
output_loc="$working_dir/$encode_dest/$category/$feature_name/$feature_name".mkv
if [[ ! -z "$working_dir" ]] && [[ ! -z "$encode_dest" ]] && [[ ! -z "$category" ]] && [[ ! -z "$feature_name" ]]; then
  edebug "valid output directory, creating"
  mkdir -p "$working_dir/$encode_dest/$category/$feature_name"
else
  eerror "error with necessary variables to create final output location for handbrake"
  exit 65
fi
edebug "output_loc is: $output_loc"
#display the final full options passed to handbrake
edebug "Final HandBrakeCLI Options are: $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options"
#
# Set out how to get information for progress bar, see notes in helper_script.sh
get_max_progress () {
  echo 100
}
#
get_total_progress () {
  #We use this variable in this instance as we need to manipulate the output so interger and no leading zero. eg. '1' no '01'
  #tot_progress_result=$(grep '"Progress":' "$working_dir/temp/$bluray_name"/handbrake.log | tail -1 | cut -d '.' -f 2 | cut -d ',' -f 1 | cut -c-2)
  tot_progress_result=$(grep "Progress: {" -A 8 handbrake.log | grep '"Scanning"' -A 3 | grep '"Progress"' | tail -1 | cut -d '.' -f 2 | cut -d ',' -f 1 | cut -c-2)
  tot_progress_result=$((10#$tot_progress_result))
  echo $tot_progress_result
}
#
if [[ $rip_only != "1" ]]; then
  edebug "${colbor}handbrake running...${colrst}"
  #HandBrakeCLI $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options > /dev/null 2>&1 &
  unit_of_measure="percent"
  progress_bar2_init
  HandBrakeCLI $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options > "$working_dir"/temp/"$bluray_name"/handbrake.log 2>&1 &
  makemkv_pid=$!
  pid_name=$makemkv_pid
  sleep 10s # to give time file to be created and data being inputted
  progress_bar2_init
  #check for any non zero errors
  if [ $? -eq 0 ]; then
    edebug "...handbrake conversion of: $bluray_name complete."
  else
    eerror "...handbrake produced an error, code: $?"
    exit 66
  fi
fi
#
#+------------------------------------+
#+---"Clean Up Temp Files & Source"---+
#+------------------------------------+
# clean temp files...if thats not overriden
if [[ $temp_clean_override == "" ]]; then
  if [[ -d "$working_dir/temp/$bluray_name" ]]; then
    cd "$working_dir/temp" || { edebug "Failure changing to temp working directory"; exit 65; }
    rm -r "$bluray_name"
  fi
fi
#
#+-------------------+
#+---"Script Exit"---+
#+-------------------+
if [ -d /tmp/"$lockname" ]; then
  rm -r /tmp/"$lockname"
  if [[ $? -ne 0 ]]; then
      eerror "error removing lockdirectory"
      exit 65
  else
      enotify "successfully removed lockdirectory"
  fi
fi
esilent "$lockname completed"
exit 0
