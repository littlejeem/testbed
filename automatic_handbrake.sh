#!/usr/bin/env bash
#
#
log=/home/jlivin25/bin/scriptlogs/automatic_handbrake2.log
logging_date=$(echo "`date +%d/%m/%Y` - `date +%H:%M:%S`")
echo "############################################################## - $logging_date: Script Started - ##############################################################"
echo "############################################################## - $logging_date: Script Started - ##############################################################" > $log
#+----------------------------------------------+
#+---"Read In Command Line Overrides (flags)"---+
#+----------------------------------------------+
while getopts r:e:t:q:c:d: flag
do
    case "${flag}" in
        r) rip_only=${OPTARG};;
        e) encde_only=${OPTARG};;
        t) title_override=${OPTARG};;
        q) quality_override=${OPTARG};;
        c) clean_override=${OPTARG};;
        d) delete_override=${OPTARG};;
    esac
done
echo "only rip blu-ray, no encode: $rip_only";
echo "only rip blu-ray, no encode: $rip_only" >> $log
echo "only encode, no rip: $encode_only";
echo "only encode, no rip: $encode_only" >> $log
echo "title: $title_override";
echo "title: $title_override" >> $log
echo "quality override: $quality_override";
echo "quality override: $quality_override" >> $log
echo "clean temp: $clean_override";
echo "clean temp: $clean_override" >> $log
echo "delete_source: $delete_override";
echo "delete_source: $delete_override" >> $log
#
#
#+---------------------+
#+---Source OMDB api---+
#+---------------------+
source /home/jlivin25/bin/omdb_key
#
#
#+-------------------+
#+---Set functions---+
#+-------------------+
function convert_secs () {
  #from here https://stackoverflow.com/questions/12199631/convert-seconds-to-hours-minutes-seconds
  num=$(secs)
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
  printf "$day:$hour:$min"
}
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
source_drive="disc:0"
dev_drive="/dev/sr0"
working_dir="/home/jlivin25"
category="blurays"
rip_dest="Rips"
encode_dest="Encodes"
bluray_name=$(blkid -o value -s LABEL "$dev_drive")
bluray_name=${bluray_name// /_}
echo "bluray name is $bluray_name" >> $log
#
#
if [[ $encode_only != "y" ]]; then
  makemkvcon backup "$source_drive" "$working_dir"/"$rip_dest"/"$category"/"$bluray_name"
fi
#
#
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
source_options="--main-feature"
output_loc="$working_dir"/"$encode_dest"/"$category"/"$bluray_name".mkv
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
  HandBrakeCLI --json -i $source_loc -t 0 &> titles_scan.json
  #
  #
  #+---------------------------+
  #+---"Identify Main Title"---+
  #+---------------------------+
  #we search the file created in Handbrake Title Scan for the main titles and store in a variable
  auto_find_main_feature=$(grep -w "Found main feature title" titles_scan.json)
  echo "$auto_find_main_feature" >> $log
  echo $auto_find_main_feature
  #we cut unwanted "Found main feature title " text from the variable
  auto_find_main_feature=${auto_find_main_feature:25}
  echo "auto_find_main_feature cut to $auto_find_main_feature" >> $log
  echo $auto_find_main_feature
  ############################################################################################
  ### NEED SOME KIND OF TEST TO IDENTIFY IF THIS HAS FAILED AND USE ALTERNATIVE METHOD?    ###
  ### SOMETHING LIKE IF $main_feature IS EMPTY DO ALTERNATIVE ACTION, ELSE DO THE NEXT BIT ###
  ############################################################################################
  #
  #
  #+------------------------------+
  #+---"Get main title details"---+
  #+------------------------------+
  #now we know the main title we scan it using handbrake and dump into another .json file
  HandBrakeCLI --json -i $source_loc -t $auto_find_main_feature --scan > main_feature_scan.json
  #
elif [[ $title_override != "" ]]; then
  HandBrakeCLI --json -i $source_loc -t $title_override --scan > main_feature_scan.json
fi
#
#
#+------------------------------------------------------+
#+---"Trim unwanted text from main_feature_scan.json"---+
#+------------------------------------------------------+
#we use sed to take all text after (inclusive) "Version: {"from main_feature_scan.json and put it into main_feature_scan_trimmed.json
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
#at this point the data is ready for 'parsing'
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
chosen_title_duration=
#
#
#+--------------------------+
#+---Get OMDB information---+
#+--------------------------+
#OMDB Syntax is: http://www.omdbapi.com /? SEARCHTERM & apikey=APIKEY
#eg https://www.omdbapi.com/?t=Harry%20Potter&apikey=452a0e3
echo "submitting info to omdb"
echo "submitting info to omdb" >> $log
omdb_title_result=$(curl -X GET --header "Accept: */*" "http://www.omdbapi.com/?t=$feature_name&apikey=$omdb_apikey")
echo "returned data from omdb is $omdb_title_result"
echo "returned data from omdb is $omdb_title_result" >> $log
#
omdb_runtime_result=$(echo $omdb_title_result | jq --raw-output '.Runtime')
omdb_runtime_result=${omdb_runtime_result%????}
echo "omdb runtime is $omdb_runtime_result mins"
echo "omdb runtime is $omdb_runtime_result" >> $log

#+-------------------------------+
#+---Sanity check chosen title---+
#+-------------------------------+
#add some checking of chosen title
#FIRST NEED TO FIND WAY TO CONVERT $omdb_runtime_result to seconds
secs=$((omdb_runtime_result*60))
#now we convert seconds to HH:MM using defined function
check=$(convert_secs)
#we use this to grep handbrake titles_scan.json. -A is lines after, -B lines before, -C is for both, the digit is how many
grep -C 2 $check titles_scan.json
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
if [[ $title_override != "" ]]; then
  source_options="-t $title_override"
  echo "title override selected, using $title_override"
  echo "title override selected, using $title_override" >> $log
fi
echo "source options are: $source_options"
echo "source options are: $source_options" >> $log
#
#
echo "Final HandBrakeCLI Options are: $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options"
echo "Final HandBrakeCLI Options are: $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options" >> $log
#
#
if [[ $rip_only != "y" ]]; then
  HandBrakeCLI $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options
fi
#
#
if [[ $clean_override != "y" ]]; then
  cd $working_dir/temp
  rm *
fi
echo "############################################################## - $logging_date: Script Complete - ##############################################################"
echo "############################################################## - $logging_date: Script Complete - ##############################################################" >> $log
