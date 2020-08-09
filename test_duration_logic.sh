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
function title_message1 () {
  echo "There are two titles matching the online (omdb) runtime for $feature_name, these are titles $title1 and $title2."
  echo "There are two titles matching the online (omdb) runtime for $feature_name, these are titles $title1 and $title2." >> $log
  test_title_match
}
#
function title_message2 () {
  echo "One title matches the online (omdb) runtime for $feature_name, this is $title1"
  echo "One title matches the online (omdb) runtime for $feature_name, this is $title1" >> $log
  test_title_match
}
#
function test_title_match () {
  if [[ "$auto_find_main_feature" = ["$title1""$title2"] ]]
  #read this for the above https://stackoverflow.com/questions/22259259/bash-if-statement-to-check-if-string-is-equal-to-one-of-several-string-literals
  then
    echo "one of these matches handbrakes automatically found main feature $auto_find_main_feature, continuing as is"
    echo "one of these matches handbrakes automatically found main feature $auto_find_main_feature, continuing as is" >> $log
  else
    auto_find_main_feature=$(echo $title1)
    echo "handbrake automatically found main feature is set at $auto_find_main_feature, this doesnt match runtime found online, using 1st track matching online runtime. Selected track is now $auto_find_main_feature"
    echo "handbrake automatically found main feature is set at $auto_find_main_feature, this doesnt match runtime found online, using 1st track matching online runtime. Selected track is now $auto_find_main_feature$" >> $log
  fi
}
#
#

source /home/jlivin25/bin/omdb_key
source_loc="/home/jlivin25/Rips/blurays/HARRY_POTTER_7_PART_2"
cd /home/jlivin25/Rips/temp/HARRY_POTTER_7_PART_2
HandBrakeCLI --json -i $source_loc -t 0 --main-feature &> titles_scan.json
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
#
#
feature_name=$(jq --raw-output '.[].TitleList[].Name' main_feature_scan_trimmed.json | head -n 1 | sed -e "s/ /_/g")
#
omdb_title_result=$(curl -X GET --header "Accept: */*" "http://www.omdbapi.com/?t=$feature_name&apikey=$omdb_apikey")
#
echo $omdb_title_result
#
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
#
check=$(convert_secs)
#
echo $secs
#
grep -B 2 $check titles_scan.json
#
grep -B 2 $check titles_scan.json > titles_duration
#
title1=$(awk 'NR==1' titles_duration)
title2=$(awk 'NR==5' titles_duration)
echo $title1
echo $title2
title1=${title1: -2}
title2=${title2: -2}
echo $title1
echo $title2
if [ $title2 == "" ]
then
  title_message2
else
  title_message1
fi
