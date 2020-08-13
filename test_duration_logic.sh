#!/usr/bin/env bash
#
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
  if [[ "$auto_find_main_feature" = ["$title1""$title2"] ]]
  #read this for the above https://stackoverflow.com/questions/22259259/bash-if-statement-to-check-if-string-is-equal-to-one-of-several-string-literals
  then
    echo "online check resulted in title(s) $title1, $title2, one of these mataches handbrakes automatically found main feature $auto_find_main_feature, continuing as is"
  else
    echo -e "${red_highlight} online check resulted in title(s) $title1, $title2 being identified. Neither match handbrakes automatically found main feature whcih is title $auto_find_main_feature, selecting one of these at random."
    rm main_feature_scan.json main_feature_scan_trimmed.json
    auto_find_main_feature=$(echo $title1)
    prep_title_file
  fi
}
#
function prep_title_file() {
  HandBrakeCLI --json -i $source_loc -t $auto_find_main_feature --scan > main_feature_scan.json
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
}
#
#
red_highlight='\033[0;31m'
source /home/jlivin25/bin/omdb_key
source_loc="/home/jlivin25/Rips/blurays/HARRY_POTTER_7_PART_1"
cd /home/jlivin25/Rips/temp/HARRY_POTTER_7_PART_1
#
#
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
####################################################
###this is the point at which '39' is identified ###
####################################################

#
#
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
#
omdb_title_result=$(curl -X GET --header "Accept: */*" "http://www.omdbapi.com/?t=$feature_name&apikey=$omdb_apikey")
#
echo $omdb_title_result
#####################################################################
### Can use this 'title' later to pretty up the output file name? ###
#####################################################################
#
#
#+---------------------------------------------+
#+---Generate checking data from online info---+
#+---------------------------------------------+
omdb_runtime_result=$(echo $omdb_title_result | jq --raw-output '.Runtime')
#
echo $omdb_runtime_result
#
omdb_runtime_result=${omdb_runtime_result%????}
#
echo "omdb runtime is $omdb_runtime_result mins"
#
echo $omdb_runtime_result
#
secs=$((omdb_runtime_result*60))
echo $secs
#
check=$(convert_secs)
#
title1=$(grep -B 2 $check titles_scan.json | awk 'NR==1')
title2=$(grep -B 2 $check titles_scan.json | awk 'NR==5')
echo $title1
echo $title2
title1=${title1: -2}
title2=${title2: -2}
echo $title1
echo $title2
#+------------------------------------+
#+---Method 1 checked with Method 2---+
#+------------------------------------+
#
test_title_match
