#!/usr/bin/env bash
#define functions
#
#
#+-----------------------+
#+---Logging Functions---+
#+-----------------------+
tty -s && function log()     {     echo "$(date +%b"  "%-d" "%T)" " "INFO: "$@"; }
tty -s && function log_deb() {     echo "$(date +%b"  "%-d" "%T)" DEBUG: "$@"; }
tty -s && function log_err() { >&2 echo "$(date +%b"  "%-d" "%T)" ERROR: "$@"; }
tty -s || function log()     { logger -t INFO $(basename $0) "$@"; }
tty -s || function log_deb() { logger -t DEBUG $(basename $0) "$@"; }
tty -s || function log_err() { logger -t ERROR $(basename $0) -p user.err "$@"; }











get_folder_manual () {
  mkdir /home/jlivin25/array_test/conglomerated
  read -a names #makes an array called 'names' from the entries entered by user
  array_count=${#names[@]} #counts the number of elements in the array and assigns to the variable cd_names
  for (( i=0; i<$array_count; i++)); do #basically says while the count (starting from 0) is less than the value in cd_names do the next bit
    echo "${names[$i]}" ;
    if [[ -d /home/jlivin25/array_test/"${names[$i]}" ]]; then
      echo "cd"$i" location found, continuing"
      cp -r /home/jlivin25/array_test/"${names[$i]}" /home/jlivin25/array_test/conglomerated/
      rm -r /home/jlivin25/array_test/"${names[$i]}"
    else
      echo "input error; array element $i ${names[$i]}, doesn't exist, check and try again"
      exit
    fi
  done
}
#
get_folder_auto () {
  mkdir /home/jlivin25/array_test/conglomerated
  # use nullglob in case there are no matching files
  shopt -s nullglob
  names=(/home/jlivin25/array_test/*)
  array_count=${#names[@]} #counts the number of elements in the array and assigns to the variable cd_names
  for (( i=0; i<$array_count; i++)); do #basically says while the count (starting from 0) is less than the value in cd_names do the next bit
    echo "${names[$i]}" ;
    if [[ -d /home/jlivin25/array_test/"${names[$i]}" ]]; then
      echo "cd"$i" location found, continuing"
      cp -r /home/jlivin25/array_test/"${names[$i]}" /home/jlivin25/array_test/conglomerated/
      rm -r /home/jlivin25/array_test/"${names[$i]}"
    else
      echo "input error; array element $i ${names[$i]}, doesn't exist, check and try again"
      exit
    fi
  done
}
#
#
#start script
#1st get user choice
if [[ $user_choice = "a" ]]; then
  get_folder_auto
elif [[ $user_choice = "m" ]]; then
  get_folder_manual
fi
#
exit 0
