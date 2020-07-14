#!/usr/bin/env bash
#
#Unknowns & Removed
#--noscan
#--cache=1024
#--directio=true
#-D 0.0,0.0 -4
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
source_loc="/home/jlivin25/Rips/blurays/Interstellar"
source_options="--main-feature"
output_loc="/home/jlivin25/Rips/blurays/Interstellar_AUTO.mkv"
output_options="-f mkv"
video_options="-e x264 --encoder-preset medium --encoder-tune film --encoder-profile high --encoder-level 4.1 -q 20.0"
#audio_options="-E copy --audio-copy-mask dtshd,truehd,dts,ac3 --audio-fallback ffac3 -B 160,160 --mixdown 5point1 -R Auto,Auto"
#audio_options="-E copy:dtshd,copy:truehd,copy:dts --audio-copy-mask dtshd,truehd,dts"
#"this one worked"
#audio_options="-a 3 -E copy --audio-copy-mask dtshd,truehd,dts,flac"
#audio_options="-a 3,3 -E ac3,copy:truehd -6 dpl2,none -R Auto,Auto -B 160,0 -D 0,0 --gain 0,0 --audio-fallback ac3"
picture_options="--crop 0:0:0:0 --loose-anamorphic --keep-display-aspect --modulus 2"
filter_options="--decomb"
subtitle_options="-N eng -F scan"
#
#
#+---------------------------+
#+---Handbrake Titles Scan---+
#+---------------------------+
#Tells handbrake to use .json formatting and scan all titles in the source location for the main feature then send the results to a file
HandBrakeCLI --json -i $source_loc -t 0 --main-feature &> titles_scan.json

#+---------------------------+
#+---"Identify Main Title"---+
#+---------------------------+
#we search the file created in Handbrake Title Scan for the main titles and store in a variable
auto_find_main_feature=$(grep -w "Found main feature title" titles_scan.json)
############################################################################################
### NEED SOME KIND OF TEST TO IDENTIFY IF THIS HAS FAILED AND USE ALTERNATIVE METHOD?    ###
### SOMETHING LIKE IF $main_feature IS EMPTY DO ALTERNATIVE ACTION, ELSE DO THE NEXT BIT ###
############################################################################################
#
#we cut unwanted "Found main feature title " text from the variable
auto_find_main_feature=${auto_find_main_feature:25}
#
#
#+------------------------------+
#+---"Get main title details"---+
#+------------------------------+
#now we know the main title we scan it using handbrake and dump into another .json file
HandBrakeCLI --json -i $source_loc -t $auto_find_main_feature --scan &> main_feature_scan.json
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
#now trim out the error line where '  HandBrake has exited.' is in the middle of the .json data
sed -i '/  HandBrake has exited./d' main_feature_scan_trimmed.json
#at this point the data is ready for 'parsing'
#
#
#+-----------------------+
#+---"Parse JSON Data"---+
#+-----------------------+
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
HandBrakeCLI $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options
