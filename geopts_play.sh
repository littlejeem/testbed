#!/usr/bin/env bash
#
#
while getopts t:q:s:c: flag
do
    case "${flag}" in
        t) title_override=${OPTARG};;
        q) quality_override=${OPTARG};;
        s) source_clean_override=${OPTARG};;
        c) temp_clean_override=${OPTARG};;
    esac
done
echo "title overriden now: $title_override";
echo "quality overriden, now: $quality_override";
echo "cleaning source overriden?: $source_clean_override";
echo "cleaning temp overriden?: $temp_clean_override";

if [[ $title_override == "" ]]; then
  echo "no title override applied"
elif [[ $title_override == "y" ]]; then
  echo -e "title override selected\chosen title is $title_override"
fi

if [[ $quality_override == "" ]]; then
  echo "no quality override applied"
elif [[ $quality_override == "y" ]]; then
  echo -e "quality override selected\chosen title is $quality_override"
fi

if [[ $source_clean_override == "" ]]; then
  echo "no source clean override selected"
elif [[ $source_clean_override == "y" ]]; then
  echo -e "source clean override applied\not deleting source files"
fi

if [[ $tmep_clean_override == "" ]]; then
  echo "no temp files clean override selected"
elif [[ $temp_clean_override == "y" ]]; then
  echo -e "temp clean override applied\keeping temp files for debugging"
fi
