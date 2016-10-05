#!/bin/bash

# TO DO dependencies, check if installed if not quit with warrning
# TO DO notify about the risk when copying photos
# TO DO count files changed and give a summary
# TO DO change postfix to number
# TO DO search or the files with same md5 (not only those without _ ) 
# TO DO add customized prefix prefix 
# TO DO cleanup functions
# TO DO sort by copying to destination catalog
# TO DO folder selection
# TO DO option handler
# TO DO function PRINT
# TO DO create folder per month/year
# TO DO include original name in metadata or as a prefix
# TO DO add option to rotate or compress file
# TO DO measure processing time
# TO DO add option to add script to env.

#set global variables
VERBOSE=1
DEBUG=1

function log {
  if [ "$VERBOSE" = 1 ] ; then
    echo -e "$@"
  fi
}  

function debug {
  if [ "$DEBUG" = 1 ] ; then
    echo -e "DEBUG : $@"
  fi
}  

function rename {
  file=$1
  echo "++++++++++++++++++++++++++"
  echo "Processing $file file..."
  # take action on each file. $f store current file name

  # get directory
  DIR=`echo "$file" | grep -Eo '.*[/]'`
    
  # read creation time from metadata
  CREATED=`exiftool "$file" | grep -m 1 "Create"`

  #extract date and time and reformat
  DATE=`echo $CREATED | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}' | awk -F '[:]' '{print $1"-"$2"-"$3}'`
  TIME=`echo $CREATED | grep -Eo '[0-9]{2}:[0-9]{2}:[0-9]{2}$' | awk -F '[:]' '{print $1"_"$2"_"$3}'`

  # read model name and replace spaces with underscore
  MODEL=`exiftool "$file" | grep "Camera Model Name" | cut -d : -f 2 | cut -c 2-30 | tr ' ' '_'`

  # get file extension
  EXT=`echo "$file" | awk -F '[^[:alpha:]]' '{ print $NF }'`

  # build output file name
  OUTPUT="$DIR$DATE $TIME $MODEL.$EXT"


POSTFIX=""
MD_IN=`md5 "$file" | awk -F '[=]' '{print $2}'` 

# skoncz jesli istnieje imd 5 rowne lub nie istnieje
debug "postfix : $POSTFIX"
PROCESSED=0
while [ "$PROCESSED" = 0 ] ; do

MD_OUT=`md5 "$OUTPUT" | awk -F '[=]' '{print $2}'`

# if same file (same md5) exists do nothing
if [ -f "$OUTPUT" ] && [ "$MD_IN" == "$MD_OUT" ] ; then
	log "File exists"
	PROCESSED=1
# if file exists, but it's different build a new name (increment)
elif [ -f "$OUTPUT" ] && [ "$MD_IN" != "$MD_OUT" ] ; then
	log "DEBUG : $OUTPUT"
    POSTFIX=$POSTFIX"_"
    OUTPUT="$DIR$DATE $TIME $MODEL$POSTFIX.$EXT"
else
	log "DEBUG : $OUTPUT"
  	log "DEBUG MD_IN  : $MD_IN"
	log "DEBUG MD_OUT : $MD_OUT"

	echo "Copying file to "$OUTPUT
	cp "$file" "$OUTPUT"	
	PROCESSED=1
fi
done

log " ======================== "

}

# rename all photos (*.jpg, *.JPG, *.jpeg)
find . -type f \( -name "*.jpg" -or -name "*.jpeg" -or -name "*.JPG" \) | while read file; do rename "$file"; done