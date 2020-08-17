#!/usr/bin/env bash
#
#
#+---------------------------------------------+#
#+---Use Geopts for flag selected parameters---+#
#+---------------------------------------------+#
helpFunction()
{
   echo ""
   echo "Usage: $0 -r y -e y -t ## -q ## -s y -c y"
   echo "Usage: $0"
   echo -e "\t Running the script with not flags causes default behaviour"
   echo -e "\t-r Rip Override: Will cause the script to skip the disc rip and encode only"
   echo -e "\t-e Encode Override: Will cause the script to rip the disc but not encode to container"
   echo -e "\t-t Manually provide the title to rip eg. -t 42"
   echo -e "\t-q Manually provide the quality to encode in handbrake, eg. -q 21. default value is 19, anything lower than 17 is considered placebo"
   echo -e "\t-s Source Override: By default the script removes the source files on completion. Setting parameter eg. -s y, will keep the files"
   echo -e "\t-c Temp Override: By default the script removes any temp fileson completion. Setting parameter eg. -c y, will keep the files, useful if debugging"
   exit 1 # Exit script after printing help
}
#
while getopts r:e:t:q:s:c: flag
do
    case "${flag}" in
        r) rip_only=${OPTARG};;
        e) encode_only=${OPTARG};;
        t) title_override=${OPTARG};;
        q) quality_override=${OPTARG};;
        s) source_clean_override=${OPTARG};;
        c) temp_clean_override=${OPTARG};;
        h) helpFunction;;
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
  else
    echo "Error: -r is not a 'y' or 'yes'."
    exit 2
fi
# -e
if [[ $encode_only == "" ]]; then
  echo "no encode override, script will encode to container"
#now test to make sure a number, see @Inian answer here https://stackoverflow.com/questions/41858997/check-if-parameter-is-value-x-or-value-y
elif [[ "$encode_only" =~ ^(y|yes|Yes|YES|Y)$ ]]; then
  echo "encode override selected, skipping encode"
  else
    echo "Error: -e is not a 'y' or 'yes'"
    exit 2
fi
# -t
if [[ $title_override == "" ]]; then
  echo "no title override applied"
#now test to make sure a number, see @Joseph Shih answer here https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
elif echo "$title_override" | grep -qE '^[0-9]+$'; then
  echo "title override selected, chosen title is $title_override"
  else
    echo "Error: -t is not a number."
    exit 2
fi
# -q
if [[ $quality_override == "" ]]; then
  echo "no quality override applied"
#now test to make sure a number, see @Joseph Shih answer here https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
elif echo "$quality_override" | grep -qE '^[0-9]+$'; then
  echo "quality override selected, chosen title is $quality_override"
else
  echo "Error: -q is not a number."
  exit 2
fi
# -s
if [[ $source_clean_override == "" ]]; then
  echo "no source clean override selected"
elif [[ $source_clean_override == "y" ]]; then
  echo "source clean override applied, not deleting source files"
fi
# -c
if [[ $temp_clean_override == "" ]]; then
  echo "no temp files clean override selected"
elif [[ $temp_clean_override == "y" ]]; then
  echo "temp clean override applied, keeping temp files for debugging"
fi
