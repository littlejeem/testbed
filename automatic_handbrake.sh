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
source_loc=
source_options="--main-feature"
output_loc=
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
HandBrakeCLI --json -i /home/jlivin25/Rips/blurays/THE_DARK_KNIGHT -t 0 --main-feature &> titles_scan.json

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
HandBrakeCLI --json -i /home/jlivin25/Rips/blurays/THE_DARK_KNIGHT -t $auto_find_main_feature --scan &> main_feature_scan.json
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
#now we search the file for the line number of our preferred source because line number = track number of the audio
selected_audio_track=$(grep -hn "TrueHD" parsed_audio_tracks | cut -c1)
echo $selected_audio_track
#
###NEED TO DO SOMETHING ABOUT 'WEIGHTING' OF RETURNED AUDIO TRACKS?? DOES THE MAIN FEATURE HAVE MULTIPLE TRACKS WITH TRUEHD DTS-HD ETC?
#
#+-------------------------------+
#+---"Run Handbrake to Encode"---+
#+-------------------------------+
#insert the audio selection into the audio_options variable
audio_options="-a $selected_audio_track -E copy --audio-copy-mask dtshd,truehd,dts,flac"
HandBrakeCLI $options -i $source_loc $source_options -o $output_loc $output_options $video_options $audio_options $picture_options $filter_options $subtitle_options
