#!/usr/bin/env bash
#
# from here
# https://arnaudr.io/2015/12/06/bash-logging-helpers/
#
#
tty -s && function log()     {     echo "$@"; }
tty -s && function log_err() { >&2 echo "$@"; }
tty -s || function log()     { logger -t $(basename $0) "$@"; }
tty -s || function log_err() { logger -t $(basename $0) -p user.err "$@"; }
#
function name(parameter) {
  #statements
}


#example useage
if ! command -v zip &> /dev/null
then
  log_err ERROR "ZIP could not be found, script won't function wihout it"
  exit 1
else
  log INFO "ZIP command located, continuing"
fi
