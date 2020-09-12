#!/usr/bin/env bash
#
#
log=/home/jlivin25/bin/scriptlogs/automatic_handbrake.log
logging_date=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S`")
echo "############################################################## - $logging_date: Script Started - ##############################################################"
echo "############################################################## - $logging_date: Script Started - ##############################################################" > $log
#
#
#+-------------------+
#+---Set functions---+
#+-------------------+
function helpFunction () {
   echo ""
   echo "Usage: $0 -r y -e y -t ## -q ## -s y -c y"
   echo "Usage: $0"
   echo -e "\t Running the script with no flags causes default behaviour"
   echo -e "\t-r Rip Only: Will cause the script to only rip the disc, not encode"
   echo -e "\t-e Encode Only: Will cause the script to encode to container only, no disc rip"
   echo -e "\t-t Manually provide the title to rip eg. -t 42"
   echo -e "\t-q Manually provide the quality to encode in handbrake, eg. -q 21. default value is 19, anything lower than 17 is considered placebo"
   echo -e "\t-s Source delete override: By default the script removes the source files on completion. Setting parameter eg. -s y, will keep the files"
   echo -e "\t-c Temp Override: By default the script removes any temp fileson completion. Setting parameter eg. -c y, will keep the files, useful if debugging"
   exit 1 # Exit script after printing help
}
#
function convert_secs () {
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
function test_title_match () {
  if [[ "$auto_find_main_feature" = ["$title1""$title2"] ]]; then
    #read this for the above https://stackoverflow.com/questions/22259259/bash-if-statement-to-check-if-string-is-equal-to-one-of-several-string-literals
    echo "online check resulted in title(s) $title1, $title2, one of these mataches handbrakes automatically found main feature $auto_find_main_feature, continuing as is"
    echo "online check resulted in title(s) $title1, $title2, one of these mataches handbrakes automatically found main feature $auto_find_main_feature, continuing as is" >> $log
  elif [[ "$title2" = "" ]]; then
    #then title 1 is set but if $title2 is valid $title2 is set
    echo -e "${red_highlight} online check resulted in title $title1 being identified. No match found to handbrakes automatically found main feature which is currently title $auto_find_main_feature."
    echo -e "${red_highlight} online check resulted in title $title1 being identified. No match found to handbrakes automatically found main feature which is currently title $auto_find_main_feature." >> $log
    auto_find_main_feature=$(echo $title1)
    prep_title_file
  else
    echo -e "${red_highlight} online check resulted in titles $title1, $title2 being identified. No match to handbrakes automatically found main feature which is title $auto_find_main_feature, selecting title $title2."
    echo -e "${red_highlight} online check resulted in titles $title1, $title2 being identified. No match to handbrakes automatically found main feature which is title $auto_find_main_feature, selecting title $title2." >> $log
    auto_find_main_feature=$(echo $title2)
    #we choose title 2 when there are 2 detected as this better than 50% right most of the time imo.
    prep_title_file
  fi
}
#
function prep_title_file() {
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
#
#+-------------------------+
#+---"Echo Colour Usage"---+
#+-------------------------+
red='\033[0;31m'
yellow='\033[1;33m'
green='\033[0;32m'
nc='\033[0m' # No Color
#
#
#+----------------------------------------------+
#+---"Read In Command Line Overrides (flags)"---+
#+----------------------------------------------+
while getopts r:e:t:q:s:c:h flag
do
    case "${flag}" in
        r) rip_only=${OPTARG};;
        e) encode_only=${OPTARG};;
        t) title_override=${OPTARG};;
        q) quality_override=${OPTARG};;
        s) source_clean_override=${OPTARG};;
        c) temp_clean_override=${OPTARG};;
        h) helpFunction;;
        ?) helpFunction;;
    esac
done
#
#
#+---------------------------------------------+#
#+---Test selected Geopts flags for validity---+#
#+---------------------------------------------+#
# -r
if [[ $rip_only == "" ]]; then
  echo "no rip override, script will rip disc"
#now test to make sure a number, see @Inian answer here https://stackoverflow.com/questions/41858997/check-if-parameter-is-value-x-or-value-y
elif [[ "$rip_only" =~ ^(y|yes|Yes|YES|Y)$ ]]; then
  echo "rip override selected, skipping rip"
  rip_only=1
else
  echo "Error: -r is not a 'y' or 'yes'."
  helpFunction
fi
# -e
if [[ $encode_only == "" ]]; then
  echo "no encode override, script will encode to container"
#now test to make sure a number, see @Inian answer here https://stackoverflow.com/questions/41858997/check-if-parameter-is-value-x-or-value-y
elif [[ "$encode_only" =~ ^(y|yes|Yes|YES|Y)$ ]]; then
  echo "encode override selected, skipping encode"
  encode_only=1
  else
    echo "Error: -e is not a 'y' or 'yes'"
    helpFunction
fi
# -t
if [[ $title_override == "" ]]; then
  echo "no title override applied"
#now test to make sure a number, see @Joseph Shih answer here https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
elif echo "$title_override" | grep -qE '^[0-9]+$'; then
  echo -e "title override selected, chosen title is $title_override"
  else
    echo "Error: -t is not a number."
    helpFunction
fi
# -q
if [[ $quality_override == "" ]]; then
  echo "no quality override applied"
#now test to make sure a number, see @Joseph Shih answer here https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
elif echo "$quality_override" | grep -qE '^[0-9]+$'; then
  echo -e "quality override selected, chosen quality is $quality_override"
else
  echo "Error: -q is not a number."
  helpFunction
fi
# -s
if [[ $source_clean_override == "" ]]; then
  echo "no source clean override selected"
elif [[ $source_clean_override == "y" ]]; then
  echo -e "source clean override applied, not deleting source files"
fi
# -c
if [[ $temp_clean_override == "" ]]; then
  echo "no temp files clean override selected"
elif [[ $temp_clean_override == "y" ]]; then
  echo -e "temp clean override applied, keeping temp files for debugging"
fi
#
#
#+----------------------------+
#+---Source necessary files---+
#+----------------------------+
#source $HOME/.config/
source /home/jlivin25/bin/omdb_key
#
#+----------------------------------+
#+---Check Enough Space Remaining---+
#+----------------------------------+
#will only work once variables moved to config script
space_left=$(df $working_dir | awk '/[0-9]%/{print $(NF-2)}')
if [ "$space_left" -le "65000000" ]; then
  echo "not enough space to run script"
  exit 1
fi
#
#
#+----------------------------+
#+---Configure Disc Ripping---+
#+----------------------------+
if [[ $quality_override == "" ]]; then
  quality="19.0"
else
  quality=$(echo $quality_override)
fi
echo $quality
echo "quality selected is $quality" >> $log
###############################
### Move to a settings file ###
###############################
  source_drive="disc:0"
  dev_drive="/dev/sr0"
  working_dir="/home/jlivin25"
  category="blurays"
  rip_dest="Rips"
  encode_dest="Encodes"
###############################
###                         ###
###############################
bluray_name=$(blkid -o value -s LABEL "$dev_drive")
bluray_name=${bluray_name// /_}
# pretty up the log
echo "###############################" >> $log
echo "### $date - $bluray_name ###" >> $log
echo "###############################" >> $log
echo -e "${green}bluray name is $bluray_name ${nc}"
#
#
if [ "$encode_only" != "1" ]; then
  echo -e "${green}makemakv running${nc}"
  makemkvcon backup --decrypt "$source_drive" "$working_dir"/"$rip_dest"/"$category"/"$bluray_name"
if [ "$rip_only" != "1" ]; then
#+-------------------------------+
#+---"HandBrake Structure Key"---+
#+-------------------------------+
#HandBrakeCLI [options] -i <source> source_options -o <destination> output_options video_options audio_options picture_options filter_options
#
#
#+------------------------+
#+---"User Set Options"---+
#+------------------------+
options="--no-dvdna"
#source_loc="$working_dir"/"$rip_dest"/"$bluray_name"
source_loc="$working_dir"/"$rip_dest"/"$category"/"$bluray_name"
output_options="-f mkv"
video_options="-e x264 --encoder-preset medium --encoder-tune film --encoder-profile high --encoder-level 4.1 -q $quality -2"
picture_options="--crop 0:0:0:0 --loose-anamorphic --keep-display-aspect --modulus 2"
filter_options="--decomb"
subtitle_options="-N eng -F scan"
#
#
#+--------------------+
#+---Temp directory---+
#+--------------------+
#make the working directory if no already exisiting
mkdir -p $working_dir/temp/$bluray_name
#this step is vital, otherwise the files below are created whereever the script is run from and will fail
cd $working_dir/temp/$bluray_name
#
#
#+---------------------------+
#+---Handbrake Titles Scan---+
#+---------------------------+
#Tells handbrake to use .json formatting and scan all titles in the source location for the main feature then send the results to a file
if [[ $title_override == "" ]]; then
  HandBrakeCLI --json -i $source_loc -t 0 --main-feature &> titles_scan.json
  #
  #
  #+--------------------------------------+
  #+---"Identify Main Title - METHOD 1"---+
  #+--------------------------------------+
  #we search the file created in Handbrake Title Scan for the main titles and store in a variable
  auto_find_main_feature=$(grep -w "Found main feature title" titles_scan.json)
  echo "$auto_find_main_feature" >> $log
  echo $auto_find_main_feature
  #we cut unwanted "Found main feature title " text from the variable
  auto_find_main_feature=${auto_find_main_feature:25}
  echo "auto_find_main_feature cut to $auto_find_main_feature" >> $log
  echo $auto_find_main_feature
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
  feature_name=$(jq --raw-output '.[].TitleList[].Name' main_feature_scan_trimmed.json | head -n 1 | sed -e "s/ /_/g")
  omdb_title_result=$(curl -X GET --header "Accept: */*" "http://www.omdbapi.com/?t=$feature_name&apikey=$omdb_apikey")
  echo $omdb_title_result
  #
  #
  #+---------------------------------------------+
  #+---Generate checking data from online info---+
  #+---------------------------------------------+
  omdb_runtime_result=$(echo $omdb_title_result | jq --raw-output '.Runtime')
  echo $omdb_runtime_result
  omdb_runtime_result=${omdb_runtime_result%????}
  echo "omdb runtime is $omdb_runtime_result mins"
  echo $omdb_runtime_result
  secs=$((omdb_runtime_result*60))
  echo $secs
  check=$(convert_secs)
  title1=$(grep -B 2 $check titles_scan.json | awk 'NR==1')
  title2=$(grep -B 2 $check titles_scan.json | awk 'NR==5')
  title1=${title1: -2}
  title2=${title2: -2}
  echo $title1
  echo $title2
  #
  #
  #+------------------------------------+
  #+---Method 1 checked against Method 2---+
  #+------------------------------------+
  test_title_match
  #
  #
elif [[ $title_override != "" ]]; then
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
#this command pipes our trimmed file into 'jq' what we get out is a list of audio track names
main_feature_parse=$(jq '.[].TitleList[].AudioList[].Description' main_feature_scan_trimmed.json > parsed_audio_tracks)
#
#
#+--------------------------------+
#+---Determine Availiable Audio---+
#+--------------------------------+
#First we search the file for the line number of our preferred source because line number = track number of the audio
#First lets test for TrueHD
True_HD=$(grep -hn "TrueHD" parsed_audio_tracks | cut -c1)
echo $True_HD
#Now lets test for DTS-HD
Dts_hd=$(grep -hn "DTS-HD" parsed_audio_tracks)
Dts_hd=$(echo $Dts_hd | cut -c1)
echo $Dts_hd
#Now lets test for DTS
Dts=$(grep -hn "(DTS)" parsed_audio_tracks)
Dts=$(echo $Dts | cut -c1)
echo $Dts
#Finally lets test for AAC
Ac3=$(grep -hn "AC3" parsed_audio_tracks)
Ac3=$(echo $Ac3 | cut -c1)
echo $Ac3
#
#Now assign the results booleans
if [[ "$True_HD" != "" ]]; then
  True_HD_boolean=true
else
  True_HD_boolean=false
fi
echo "True HD= $True_HD_boolean"
#
if [[ "$Dts_hd" != "" ]]; then
  Dts_hd_boolean=true
else
  Dts_hd_boolean=false
fi
echo "DTS-HD MA= $Dts_hd_boolean"
#
if [[ "$Dts" != "" ]]; then
  Dts_boolean=true
else
  Dts_boolean=false
fi
echo "DTS= $Dts_boolean"
#
if [[ "$Ac3" != "" ]]; then
  Ac3_boolean=true
else
  Ac3_boolean=false
fi
echo "AC3= $Ac3_boolean"
#
#
#+--------------------------------+
#+---Determine Availiable Audio---+
#+--------------------------------+
#Now we make some decisons about audio choices
if [[ "$True_HD_boolean" == true ]] && [[ "$Dts_hd_boolean" == false ]]; then
  selected_audio_track=$(echo $True_HD)
  echo "Selecting True_HD audio, track $True_HD"
elif [[ "$Dts_hd_boolean" == true ]] && [[ "$True_HD_boolean" == false ]]; then
  selected_audio_track=$(echo $Dts_hd)
  echo "Selecting DTS-HD audio, track $Dts_hd"
elif [[ "$Dts_hd_boolean" == false ]] && [[ "$True_HD_boolean" == false ]] && [[ "$Dts_boolean" == true ]]; then
  selected_audio_track=$(echo $Dts)
  echo "Selecting DTS audio, track $Dts"
elif [[ "$Dts_hd_boolean" == false ]] && [[ "$True_HD_boolean" == false ]] && [[ "$Dts_boolean" == false ]]; then
  selected_audio_track=1
  echo "no matches for audio types, defaulting to track 1"
fi
echo $selected_audio_track
#
#
#+-------------------------------+
#+---"Run Handbrake to Encode"---+
#+-------------------------------+
#insert the audio selection into the audio_options variable
audio_options="-a $selected_audio_track -E copy --audio-copy-mask dtshd,truehd,dts,flac"
echo "audio options passed to HandBrakeCLI are $audio_options"
echo "audio options passed to HandBrakeCLI are $audio_options" >> $log
#use our found main feature from the work at the top...
source_options="-t $auto_find_main_feature"
#...but override it if override is set
if [[ $title_override != "" ]]; then
  source_options=-"t $title_override"
  echo "title override selected, using $title_override"
  echo "title override selected, using $title_override" >> $log
fi
#display what the result is
echo "source options are: $source_options"
echo "source options are: $source_options" >> $log
#display the final full options passed to handbrake
echo "Final HandBrakeCLI Options are: $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options"
echo "Final HandBrakeCLI Options are: $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options" >> $log
#lets use our fancy name IF found online
output_loc="$working_dir"/"$encode_dest"/"$category"/"$feature_name".mkv
#
if [[ $rip_only != "1" ]]; then
  echo -e "${red}handbrake running${nc}"
  HandBrakeCLI $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options
fi
#
#
if [[ $temp_clean_override == "" ]]; then
  cd $working_dir/temp
  rm *
fi
fi
echo "############################################################## - $logging_date: Script Complete - ##############################################################"
echo "############################################################## - $logging_date: Script Complete - ##############################################################" >> $log
