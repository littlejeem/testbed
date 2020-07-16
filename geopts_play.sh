#!/usr/bin/env bash
#
#
while getopts t:q: flag
do
    case "${flag}" in
        t) title_override=${OPTARG};;
        q) quality_override=${OPTARG};;
    esac
done
echo "title: $title_override";
echo "quality: $quality_override";
