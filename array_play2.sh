#!/usr/bin/env bash
#define functions
#
#
#+-----------------------+
#+---Logging Functions---+
#+-----------------------+
#
#
#################
### "Colours" ###
#################
colblk='\033[0;30m' # Black - Regular
colred='\033[0;31m' # Red
colgrn='\033[0;32m' # Green
colylw='\033[0;33m' # Yellow
colpur='\033[0;35m' # Purple
colrst='\033[0m'    # Text Reset
#
#
#################
### "CURRENT" ###
#################
tty -s && log ()     {     echo "$(date +%b"  "%-d" "%T)" " "INFO: "$@"; }
tty -s && log_deb () {     echo "$(date +%b"  "%-d" "%T)" DEBUG: "$@"; }
tty -s && log_err () { >&2 echo "$(date +%b"  "%-d" "%T)" ERROR: "$@"; }
tty -s || log ()     { logger -t INFO $(basename $0) "$@"; }
tty -s || log_deb () { logger -t DEBUG $(basename $0) "$@"; }
tty -s || log_err () { logger -t ERROR $(basename $0) -p user.err "$@"; }
#
#
#############
### "NEW" ###
#############
#this maybe?
#http://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
"exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=3 # default to show warnings
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5

notify() { log $silent_lvl "NOTE: $1"; } # Always prints
critical() { log $crt_lvl "CRITICAL: $1"; }
error() { log $err_lvl "ERROR: $1"; }
warn() { log $wrn_lvl "WARNING: $1"; }
inf() { log $inf_lvl "INFO: $1"; } # "info" is already a command
debug() { log $dbg_lvl "DEBUG: $1"; }
log() {
    if [ $verbosity -ge $1 ]; then
        datestring=`date +'%Y-%m-%d %H:%M:%S'`
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        echo -e "$datestring $2" | fold -w70 -s | sed '2~1s/^/  /' >&3
    fi
}"
#
############################
### "USE IT LIKE THIS??" ###
############################
verbosity=4
#
#for terminal output
tty -s && notify() { log $silent_lvl "NOTE: $@"; } # Always prints
tty -s && critical() { log $crt_lvl "${colpur}CRITICAL:${colrst} $@"; }
tty -s && error() { log $err_lvl "${colred}ERROR:${colrst} $@"; }
tty -s && warn() { log $wrn_lvl "${colylw}WARNING:${colrst} $@"; }
tty -s && inf() { log $inf_lvl "${colwht}INFO:${colrst} $@"; } # "info" is already a command
tty -s && debug() { log $dbg_lvl "${colgrn}DEBUG:${colrst} $@"; }

#for logging
tty -s || notify() { log $silent_lvl "NOTE: $@"; } # Always prints
tty -s || critical() { log $crt_lvl "${colpur}CRITICAL:${colrst} $@"; }
tty -s || error() { log $err_lvl "${colred}ERROR:${colrst} $@"; }
tty -s || warn() { log $wrn_lvl "${colylw}WARNING:${colrst} $@"; }
tty -s || inf() { log $inf_lvl "${colwht}INFO:${colrst} $@"; } # "info" is already a command
tty -s || debug() { log $dbg_lvl "${colgrn}DEBUG:${colrst} $@"; }
#
#
log() {
    if [ $verbosity -ge $1 ]; then
        datestring="$(date +%b"  "%-d" "%T)"
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        echo -e "$datestring $2" | fold -w70 -s | sed '2~1s/^/  /' >&3
    fi
}
#
#
notify "this is a notification"
critical "CRITICAL MESSAGE!"
warn "this is a warning"
error "this is an error"
info "this is an information"
debug "debugging"
#
#
