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
#+--------------------------+
#+---Source helper script---+
#+--------------------------+
source /usr/local/bin/helper_script.sh
#
#
#+---------------------+
#+---"Set Variables"---+
#+---------------------+
#set default logging level, failure to set this will cause a 'unary operator expected' error
#remember at level 3 and lower, only esilent messages show, best to include an override in getopts
verbosity=3
#
version="0.3" #
script_pid=$(echo $$)
stamp=$(echo "`date +%H.%M`-`date +%d_%m_%Y`")
notify_lock=/tmp/IPChecker_notify
#pushover_title="NAME HERE" #Uncomment if using pushover
#
convert_secs () {
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
test_title_match () {
  if [[ "$auto_find_main_feature" = ["$title1""$title2"] ]]; then
    #read this for the above https://stackoverflow.com/questions/22259259/bash-if-statement-to-check-if-string-is-equal-to-one-of-several-string-literals
    edebug "online check resulted in title(s) $title1, $title2, one of these matches handbrakes automatically found main feature $auto_find_main_feature, continuing as is"
  elif [[ "$title2" = "" ]]; then
    #then title 1 is set but if $title2 is valid $title2 is set
    edebug -e "${red_highlight} online check resulted in title $title1 being identified. No match found to handbrakes automatically found main feature which is currently title $auto_find_main_feature."
    auto_find_main_feature=$(echo $title1)
    prep_title_file
  else
    edebug -e "${red_highlight} online check resulted in titles $title1, $title2 being identified. No match to handbrakes automatically found main feature which is title $auto_find_main_feature, selecting title $title2."
    auto_find_main_feature=$(echo $title2)
    #we choose title 2 when there are 2 detected as this better than 50% right most of the time imo.
    prep_title_file
  fi
}
#
prep_title_file() {
  HandBrakeCLI --json -i $source_loc -t $auto_find_main_feature --scan > main_feature_scan.json
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
}
#
#+---------------------------------------+
#+---"check if script already running"---+
#+---------------------------------------+
check_running
#
#
#+-------------------+
#+---Set functions---+
#+-------------------+
helpFunction () {
   echo ""
   echo "Usage: $0 $scriptlong"
   echo "Usage: $0 $scriptlong -G -r y -e y -t ## -q ## -s y -c y"
   echo -e "\t Running the script with no flags causes default behaviour with logging level set via 'verbosity' variable"
   echo -e "\t-S Override set verbosity to specify silent log level"
   echo -e "\t-V Override set verbosity to specify Verbose log level"
   echo -e "\t-G Override set verbosity to specify Debug log level"
   echo -e "\t-r Rip Only: Will cause the script to only rip the disc, not encode"
   echo -e "\t-e Encode Only: Will cause the script to encode to container only, no disc rip"
   echo -e "\t-t Manually provide the title to rip eg. -t 42"
   echo -e "\t-q Manually provide the quality to encode in handbrake, eg. -q 21. default value is 19, anything lower than 17 is considered placebo"
   echo -e "\t-s Source delete override: By default the script removes the source files on completion. Setting parameter eg. -s y, will keep the files"
   echo -e "\t-c Temp Override: By default the script removes any temp fileson completion. Setting parameter eg. -c y, will keep the files, useful if debugging"
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
#+------------------------+
#+---"Get User Options"---+
#+------------------------+
OPTIND=1
while getopts ":SVGHh:r:e:t:q:s:c:" opt
do
    case "${opt}" in
        S) verbosity=$silent_lvl
        edebug "-S specified: Silent mode";;
        V) verbosity=$inf_lvl
        edebug "-V specified: Verbose mode";;
        G) verbosity=$dbg_lvl
        edebug "-G specified: Debug mode";;
        r) rip_only=${OPTARG};;
        e) encode_only=${OPTARG};;
        t) title_override=${OPTARG};;
        q) quality_override=${OPTARG};;
        s) source_clean_override=${OPTARG};;
        c) temp_clean_override=${OPTARG};;
        H) helpFunction;;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
shift $((OPTIND -1))
#
#+----------------------+
#+---"Script Started"---+
#+----------------------+
# At this point the script is set up and all necessary conditions.
esilent "$lockname started"
#
#
#+-------------------------------+
#+---Configure GETOPTS options---+
#+-------------------------------+
# -r
if [[ $rip_only == "" ]]; then
  edebug "no rip override, script will rip disc"
#now test to make sure a number, see @Inian answer here https://stackoverflow.com/questions/41858997/check-if-parameter-is-value-x-or-value-y
elif [[ "$rip_only" =~ ^(y|yes|Yes|YES|Y)$ ]]; then
  edebug -e "${brown_orange}rip override selected, skipping rip${nc}"
  rip_only=1
else
  echo "Error: -r is not a 'y' or 'yes'."
  helpFunction
fi
# -e
if [[ $encode_only == "" ]]; then
  edebug "no encode override, script will encode to container"
#now test to make sure a number, see @Inian answer here https://stackoverflow.com/questions/41858997/check-if-parameter-is-value-x-or-value-y
elif [[ "$encode_only" =~ ^(y|yes|Yes|YES|Y)$ ]]; then
  edebug "encode override selected, skipping encode"
  encode_only=1
  else
    echo "Error: -e is not a 'y' or 'yes'"
    helpFunction
fi
# -t
if [[ $title_override == "" ]]; then
  edebug "no title override applied"
#now test to make sure a number, see @Joseph Shih answer here https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
elif echo "$title_override" | grep -qE '^[0-9]+$'; then
  edebug -e "${brown_orange}title override selected, chosen title is $title_override ${nc}"
  else
    echo "Error: -t is not a number."
    helpFunction
fi
# -q
if [[ $quality_override == "" ]]; then
  edebug "no quality override applied"
#now test to make sure a number, see @Joseph Shih answer here https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
elif echo "$quality_override" | grep -qE '^[0-9]+$'; then
  edebug -e "${brown_orange}quality override selected, chosen quality is $quality_override ${nc}"
else
  echo "Error: -q is not a number."
  helpFunction
fi
# -s
if [[ $source_clean_override == "" ]]; then
  edebug "no source clean override selected"
elif [[ $source_clean_override == "y" ]]; then
  edebug -e "${brown_orange}source clean override applied, not deleting source files${nc}"
fi
# -c
if [[ $temp_clean_override == "" ]]; then
  edebug "no temp files clean override selected"
elif [[ $temp_clean_override == "y" ]]; then
  edebug -e "${brown_orange}temp clean override applied, keeping temp files for debugging${nc}"
fi
#
#e.g for a drive option
#if [[ $drive_install = "" ]]; then
#  drive_number="sr0"
#  edebug "no alternative drive specified, using default: $drive_number as drive install"
#else
#  drive_number=$(echo $drive_install)
#  edebug "alternative drive specified, using: $drive_number as drive install"
#fi
#
#edebug "GETOPTS options set"
#
#
#+--------------------------+
#+---"Source config file"---+
#+--------------------------+
source /usr/local/bin/config.sh
source /usr/local/bin/omdb_key
#
#
#+--------------------------------------+
#+---"Display some info about script"---+
#+--------------------------------------+
edebug "Version of $scriptlong is: $version"
edebug "PID is $script_pid"
#
#
#+-------------------+
#+---Set up script---+
#+-------------------+
#Get environmental info
edebug "INVOCATION_ID is set as: $INVOCATION_ID"
edebug "EUID is set as: $EUID"
edebug "PATH is: $PATH"
#
#
#+----------------------------+
#+---"Main Script Contents"---+
#+----------------------------+
#Check Enough Space Remaining, will only work once variables moved to config script
space_left=$(df $working_dir | awk '/[0-9]%/{print $(NF-2)}')
if [ "$space_left" -le 65000000 ]; then
  eerror "not enough space to run rip & encode, terminating"
  exit 66
else
  edebug "Free space check passed, continuing"
fi
#
#Configure Disc Ripping
if [[ $quality_override == "" ]]; then
  quality="19.0"
else
  quality=$(echo $quality_override)
fi
edebug "quality selected is $quality"
###############################
### Move to a settings file ###
###############################
  source_drive="disc:0"
  dev_drive="/dev/sr0"
  working_dir="/home/jlivin25"
  category="blurays"
  rip_dest="Rips"
  encode_dest="Encodes"
#
#Get and use hard coded name of media
bluray_name=$(blkid -o value -s LABEL "$dev_drive")
bluray_name=${bluray_name// /_}
edebug "bluray name is: $bluray_name"
#
if [ "$encode_only" != "1" ]; then
  edebug -e "${Purple}makemakv running...${nc}"
  makemkvcon backup --decrypt "$source_drive" "$working_dir"/"$rip_dest"/"$category"/"$bluray_name" > /dev/null 2>&1 &
  if [ $? -eq 0 ]; then
    edebug "...makemkvcon bluray rip completed successfully"
  else
    error "makemkv producded an error, code: $?"
    exit 66
fi
if [ "$rip_only" != "1" ]; then
  #
  #+-------------------------------+
  #+---"HandBrake Structure Key"---+
  #+-------------------------------+
  #HandBrakeCLI [options] -i <source> source_options -o <destination> output_options video_options audio_options picture_options filter_options
  #User Set Options"
  options="--no-dvdna"
  source_loc="$working_dir"/"$rip_dest"/"$category"/"$bluray_name"
  output_options="-f mkv"
  video_options="-e x264 --encoder-preset medium --encoder-tune film --encoder-profile high --encoder-level 4.1 -q $quality -2"
  picture_options="--crop 0:0:0:0 --loose-anamorphic --keep-display-aspect --modulus 2"
  filter_options="--decomb"
  subtitle_options="-N eng -F scan"
  #
  #make the working directory if not already existing
  mkdir -p $working_dir/temp/$bluray_name
  #this step is vital, otherwise the files below are created whereever the script is run from and will fail
  cd $working_dir/temp/$bluray_name || { edebug "Failure changing to working directory temp"; exit 65; }
  #
  #
  #+---------------------------+
  #+---Handbrake Titles Scan---+
  #+---------------------------+
  #Tells handbrake to use .json formatting and scan all titles in the source location for the main feature then send the results to a file
  if [[ $title_override == "" ]]; then
    edebug "creating titles_scan.json"
    HandBrakeCLI --json -i $source_loc -t 0 --main-feature &> titles_scan.json
    #
    #
    #+--------------------------------------+
    #+---"Identify Main Title - METHOD 1"---+
    #+--------------------------------------+
    #we search the file created in Handbrake Title Scan for the main titles and store in a variable
    auto_find_main_feature=$(grep -w "Found main feature title" titles_scan.json)
    edebug "auto_find_main_feature is: $auto_find_main_feature"
    #we cut unwanted "Found main feature title " text from the variable
    auto_find_main_feature=${auto_find_main_feature:25}
    edebug "auto_find_main_feature cut to $auto_find_main_feature"
    #
    #
    #+-------------------------------------------------------------------------------------+
    #+---"Grab data from found title and trim unwanted text from main_feature_scan.json"---+
    #+-------------------------------------------------------------------------------------+
    prep_title_file
    #
    #
    #+---------------------+
    #+---Get online data---+
    #+---------------------+
    edebug "Getting online data"
    feature_name=$(jq --raw-output '.[].TitleList[].Name' main_feature_scan_trimmed.json | head -n 1 | sed -e "s/ /_/g")
    edebug "feature name is: $feature_name"
    omdb_title_result=$(curl -X GET --header "Accept: */*" "http://www.omdbapi.com/?t=$feature_name&apikey=$omdb_apikey")
    edebug "omdb title result is: $omdb_title_result"
    #
    #
    #+---------------------------------------------+
    #+---Generate checking data from online info---+
    #+---------------------------------------------+
    edebug "Getting runtime info..."
    omdb_runtime_result=$(echo $omdb_title_result | jq --raw-output '.Runtime')
    edebug "omdb_runtime_result is: $omdb_runtime_result"
    omdb_runtime_result=${omdb_runtime_result%????}
    edebug "omdb runtime is $omdb_runtime_result mins"
    secs=$((omdb_runtime_result*60))
    edebug "equal to $secs secs"
    check=$(convert_secs)
    title1=$(grep -B 2 $check titles_scan.json | awk 'NR==1')
    title2=$(grep -B 2 $check titles_scan.json | awk 'NR==5')
    title1=${title1: -2}
    title2=${title2: -2}
    edebug "title 1 is: $title1"
    edebug "title 2 is: $title2"
    #
    #
    #+---------------------------------------+
    #+---Method 1 checked against Method 2---+
    #+---------------------------------------+
    test_title_match
    #
    #
  elif [[ $title_override != "" ]]; then
    edebug "creating main_feature_scan.json"
    HandBrakeCLI --json -i $source_loc -t $title_override --scan > main_feature_scan.json
  fi
  #
  #
  #+------------------------------------------------------+
  #+---"Trim unwanted text from main_feature_scan.json"---+
  #+------------------------------------------------------+
  prep_title_file
  #
  #
  #+-----------------------+
  #+---"Parse JSON Data"---+
  #+-----------------------+
  #this command uses 'jq' and will extract the Name of the movie according to the bluray data with spaces replaced by underscores
  feature_name=$(jq --raw-output '.[].TitleList[].Name' main_feature_scan_trimmed.json | head -n 1 | sed -e "s/ /_/g")
  edebug "feature_name returned content from jq is: $feature_name"
  #this command pipes our trimmed file into 'jq', what we get out is a list of audio track names
  main_feature_parse=$(jq '.[].TitleList[].AudioList[].Description' main_feature_scan_trimmed.json > parsed_audio_tracks)
  edebug "main_feature_parse returned content from jq is: $main_feature_parse"
  #
  #
  #+--------------------------------+
  #+---Determine Availiable Audio---+
  #+--------------------------------+
  #First we search the file for the line number of our preferred source because line number = track number of the audio
  #these tests produce boolean returns
  #First lets test for TrueHD
  True_HD=$(grep -hn "TrueHD" parsed_audio_tracks | cut -c1)
  edebug "True HD present?: $True_HD"
  #Now lets test for DTS-HD
  Dts_hd=$(grep -hn "DTS-HD" parsed_audio_tracks)
  Dts_hd=$(echo $Dts_hd | cut -c1)
  edebug "DTS-HD present?: $Dts_hd"
  #Now lets test for DTS
  Dts=$(grep -hn "(DTS)" parsed_audio_tracks)
  Dts=$(echo $Dts | cut -c1)
  edebug "DTS present?: $Dts"
  #Finally lets test for AAC
  Ac3=$(grep -hn "AC3" parsed_audio_tracks)
  Ac3=$(echo $Ac3 | cut -c1)
  edebug "AC3 present?: $Ac3"
  #
  #Now assign the results booleans
  if [[ "$True_HD" != "" ]]; then
    True_HD_boolean=true
  else
    True_HD_boolean=false
  fi
  edebug "True HD= $True_HD_boolean"
  #
  if [[ "$Dts_hd" != "" ]]; then
    Dts_hd_boolean=true
  else
    Dts_hd_boolean=false
  fi
  edebug "DTS-HD MA= $Dts_hd_boolean"
  #
  if [[ "$Dts" != "" ]]; then
    Dts_boolean=true
  else
    Dts_boolean=false
  fi
  edebug "DTS= $Dts_boolean"
  #
  if [[ "$Ac3" != "" ]]; then
    Ac3_boolean=true
  else
    Ac3_boolean=false
  fi
  edebug "AC3= $Ac3_boolean"
  #
  #
  #+--------------------------------+
  #+---Determine Availiable Audio---+
  #+--------------------------------+
  #Now we make some decisons about audio choices
  if [[ "$True_HD_boolean" == true ]] && [[ "$Dts_hd_boolean" == false ]]; then
    selected_audio_track=$(echo $True_HD)
    edebug "Selecting True_HD audio, track $True_HD"
  elif [[ "$Dts_hd_boolean" == true ]] && [[ "$True_HD_boolean" == false ]]; then
    selected_audio_track=$(echo $Dts_hd)
    edebug "Selecting DTS-HD audio, track $Dts_hd"
  elif [[ "$Dts_hd_boolean" == false ]] && [[ "$True_HD_boolean" == false ]] && [[ "$Dts_boolean" == true ]]; then
    selected_audio_track=$(echo $Dts)
    edebug "Selecting DTS audio, track $Dts"
  elif [[ "$Dts_hd_boolean" == false ]] && [[ "$True_HD_boolean" == false ]] && [[ "$Dts_boolean" == false ]]; then
    selected_audio_track=1
    edebug "no matches for audio types, defaulting to track 1"
  fi
  edebug $selected_audio_track
  #
  #
  #+-------------------------------+
  #+---"Run Handbrake to Encode"---+
  #+-------------------------------+
  #insert the audio selection into the audio_options variable
  audio_options="-a $selected_audio_track -E copy --audio-copy-mask dtshd,truehd,dts,flac"
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
  #display the final full options passed to handbrake
  edebug "Final HandBrakeCLI Options are: $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options"
  #lets use our fancy name IF found online
  output_loc="$working_dir"/"$encode_dest"/"$category"/"$feature_name".mkv
  edebug "output_loc is: $output_loc"
  #
  if [[ $rip_only != "1" ]]; then
    edebug -e "${BrownOrange}handbrake running...${nc}"
    HandBrakeCLI $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options > /dev/null 2>&1 &
  fi
  #
  #
  if [[ $temp_clean_override == "" ]]; then
    cd $working_dir/temp/$bluray_name || { edebug "Failure changing to working directory"; exit 65; }
    rm -r $bluray_name
  fi
fi
#
#
#+-------------------+
#+---"Script Exit"---+
#+-------------------+
if -d /tmp/"$lockname"; then
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
