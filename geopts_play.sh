#!/usr/bin/env bash
#
#
#+---------------------------------------------+#
#+---Use Geopts for flag selected parameters---+#
#+---------------------------------------------+#
while getopts r:e:t:q:s:c: flag
do
    case "${flag}" in
        r) rip_only=${OPTARG};;
        e) encode_only=${OPTARG};;
        t) title_override=${OPTARG};;
        q) quality_override=${OPTARG};;
        s) source_clean_override=${OPTARG};;
        c) temp_clean_override=${OPTARG};;
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
