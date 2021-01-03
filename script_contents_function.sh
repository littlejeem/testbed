#!/bin/bash
#
abcde_conf_create () {
cat > /home/"$install_user"/test_abcde_flac.conf << 'EOF'
LOWDISK=y
INTERACTIVE=n
CDDBMETHOD=cddb
#
#+-------------------+
#+---Source Config---+
#+-------------------+
#source "$HOME"/.config/ScriptSettings/sync_config.sh
#----------------------------------------------------------------#
GLYRC=glyrc
GLYRCOPTS=

IDENTIFY=identify
IDENTIFYOPTS=

DISPLAYCMD=display
DISPLAYCMDOPTS="-resize 512x512 -title abcde_album_art"

CONVERT=convert
CONVERTOPTS=

ALBUMARTALWAYSCONVERT="n"

ALBUMARTFILE="folder.jpg"
ALBUMARTTYPE="JPEG"
#----------------------------------------------------------------#
CDDBCOPYLOCAL="n"
CDDBLOCALDIR="$HOME/.cddb"
CDDBLOCALRECURSIVE="y"
CDDBUSELOCAL="n"

FLACENCODERSYNTAX=flac

FLAC=flac

FLACOPTS='--verify --best'

OUTPUTTYPE="flac"

CDROMREADERSYNTAX=cdparanoia

CDPARANOIA=cdparanoia
CDPARANOIAOPTS="--never-skip=40"

CDDISCID=cd-discid

#OUTPUTDIR=$HOME/Music/Rips
OUTPUTDIR=${rip_flac}

ACTIONS=read,encode,move,clean

# Decide here how you want the tracks labelled for a standard 'single-artist',
# multi-track encode and also for a multi-track, 'various-artist' encode:
OUTPUTFORMAT='${ARTISTFILE}/${ALBUMFILE}/${TRACKNUM} - ${TRACKFILE} - ${ARTISTFILE}'
VAOUTPUTFORMAT='Various/${ALBUMFILE}/${TRACKNUM} - ${TRACKFILE} - ${ARTISTFILE}'

# single-track encode and also for a single-track 'various-artist' encode.
# (Create a single-track encode with 'abcde -1' from the commandline.)
ONETRACKOUTPUTFORMAT='${ARTISTFILE}-${ALBUMFILE}/${ALBUMFILE}'
VAONETRACKOUTPUTFORMAT='Various/${ALBUMFILE}/${ALBUMFILE}'

# This function takes out dots preceding the album name, and removes a grab
# bag of illegal characters. It allows spaces, if you do not wish spaces add
# in -e 's/ /_/g' after the first sed command.
mungefilename ()
{
  echo "$@" | sed -e 's/^\.*//' | tr -d ":><|*/\"'?[:cntrl:]"
}

# What extra options?
MAXPROCS=6                              # Run a few encoders simultaneously
PADTRACKS=y                             # Makes tracks 01 02 not 1 2
EXTRAVERBOSE=2                          # Useful for debugging
COMMENT='abcde version 2.7.2'           # Place a comment...
EJECTCD=n                              # Please eject cd when finished :-)

post_encode ()
{
ARTISTFILE="$(mungefilename "$TRACKARTIST")"
ALBUMFILE="$(mungefilename "$DALBUM")"
GENRE="$(mungegenre "$GENRE")"
YEAR=${CDYEAR:-$CDYEAR}

if [ "$VARIOUSARTISTS" = "y" ] ; then
FINDPATH="$(eval echo "$VAOUTPUTFORMAT")"
else
FINDPATH="$(eval echo "$OUTPUTFORMAT")"
fi

FINALDIR="$(dirname "$OUTPUTDIR")"
FINALDIR1="$(dirname "$OUTPUTDIR")"
C_CMD=(chown -R ${install_user}:${install_user} "$FINALDIR")
C_CMD1=(chmod -R 777 "$FINALDIR")
#echo "${C_CMD[@]}" >> tmp2.log
"${C_CMD[@]}"
"${C_CMD1[@]}"
cd "$FINALDIR"

if [ "$OUTPUTTYPE" = "flac" ] ; then
vecho "Preparing to embed the album art..." >&2
else
vecho "Not embedding album art, you need flac output.." >&2
return 1
fi
}
EOF
#
#
