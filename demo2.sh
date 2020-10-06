#!/bin/sh

SCRIPT_LOG=/home/pi/bin/SystemOut.log
touch $SCRIPT_LOG

#function Timestamp ()
#{
#  echo "$(date +%d/%m/%Y) - $(date +%H:%M:%S) - $1"
#}


function SCRIPTENTRY ()
{
 timeAndDate=`date`
 script_name="demo2.sh"
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG]  > $script_name $FUNCNAME" >> $SCRIPT_LOG
}

#function SCRIPTENTRY () {  timeAndDate=`date`;  script_name="demo2.sh";  script_name="${script_name%.*}";  echo "[$timeAndDate] [DEBUG]  > $script_name $FUNCNAME" >> $SCRIPT_LOG; }

function SCRIPTEXIT ()
{
 script_name="demo2.sh"
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG]  < $script_name $FUNCNAME" >> $SCRIPT_LOG
}

function ENTRY ()
{
 local cfn="${FUNCNAME[1]}"
 timeAndDate=`date`
 echo "[$timeAndDate] [DEBUG]  > $cfn $FUNCNAME" >> $SCRIPT_LOG
}

function EXIT ()
{
 local cfn="${FUNCNAME[1]}"
 timeAndDate=`date`
 echo "[$timeAndDate] [DEBUG]  < $cfn $FUNCNAME" >> $SCRIPT_LOG
}

function INFO ()
{
 local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date`
    echo "[$timeAndDate] [INFO]  $msg" >> $SCRIPT_LOG
}

function DEBUG ()
{
 local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date`
 echo "[$timeAndDate] [DEBUG]  $msg" >> $SCRIPT_LOG
}

function ERROR ()
{
 local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date`
    echo "[$timeAndDate] [ERROR]  $msg" >> $SCRIPT_LOG
}

SCRIPTENTRY

updateUserDetails ()
{
    ENTRY
    DEBUG "Username: $1, Key: $2"
    INFO "User details updated for $1"
    EXIT
}

INFO "Updating user details..."
updateUserDetails "cubicrace" "3445"

rc=2

if [ ! "$rc" = "0" ]
then
    ERROR "Failed to update user details. RC=$rc"
fi
SCRIPTEXIT
exit 0
