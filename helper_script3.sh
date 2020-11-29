#!/usr/bin/env bash
#
tty -s && function log()     {     echo "$@"; }
tty -s && function log_err() { >&2 echo "$@"; }
tty -s || function log()     { logger -t $(basename $0) "$@"; }
tty -s || function log_err() { logger -t $(basename $0) -p user.err "$@"; }



# log()     { [[ -t 1 ]] &&     echo "$@" || logger -t $(basename $0) "$@"; }
# log_err() { [[ -t 2 ]] && >&2 echo "$@" || logger -t $(basename $0) -p user.err "$@"; }
