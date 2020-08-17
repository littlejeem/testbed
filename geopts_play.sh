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
