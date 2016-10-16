#!/bin/bash

# TO DO dependencies, check if installed if not quit with warrning
# TO DO notify about the risk when copying photos
# TO DO count files changed and give a summary
# TO DO change postfix to number
# TO DO search or the files with same md5 (not only those without _ ) 
# TO DO add customized prefix 
# TO DO cleanup functions
# TO DO option handler
# TO DO include original name in metadata or as a prefix
# TO DO add option to rotate or compress file
# TO DO measure processing time
# TO DO add option to add script to env.
# TO DO add progress in % or number of file
# TO DO option to remove duplicates
# TO DO handle case when there is no metadata
# TO DO check system, do nothing if not recognized
# TO DO count duplicates 
# TO DO check if we have all the files if cp (run in safe mode before delete)
# TO DO count files with no metadata and log them, provide stats

#set global variables
VERBOSE=1
DEBUG=1
FILE_LOG=1
LOG_FILE="rename.log"

SORT_DIR=1
TREE_SORT=1
FOLDER="GG"
ROOT="$HOME/Desktop/test" 
ROOT="./Renamed" 

CP=1 
ROTATE=0
COMPRESS=0

# reset counters
COUNTER=0
MODIFIED=0 # FIX IT , it's not global
 
# TO DO option processing here
 
if [ "$FILE_LOG" = 1 ] ; then
  echo -e "" > $LOG_FILE
fi
      
function count {
c=0
extensions="jpg jpeg png"
for ext in $extensions; do
  c_=$(find . -maxdepth 10 -iname "*.$ext" -print0 | tr -d -c "\000" | wc -c)
  c=$(($c+$c_))
done
echo $c
exit $c
}

function log {
  if [ "$VERBOSE" = 1 ] ; then
    echo -e "$@"
      if [ "$FILE_LOG" = 1 ] ; then
        echo -e "$@" >> $LOG_FILE
      fi
  fi
}  

function debug {
  if [ "$DEBUG" = 1 ] ; then
    echo -e "DEBUG : $@"
    if [ "$FILE_LOG" = 1 ] ; then
      echo -e "DEBUG : $@" >> $LOG_FILE
    fi
  fi
}  

# count files before
FILES_IN=`count` 

function rename {
  file=$1
  log "++++++++++++++++++++++++++"

  # take action on each file. $f store current file name  
  COUNTER=$(($COUNTER + 1))
  log "Processing file $file ($COUNTER/$FILES_IN)"

  # get directory
  DIR_IN=`echo "$file" | grep -Eo '.*[/]'`
  
   # get file extension
  EXT=${file##*.}
  
  #get short file name (no extension) 
  FILE_NAME=`echo "$file" | rev | cut -d / -f 1 | sed 's/^[^.]*.//g' | rev`
   
  # read creation time from metadata
  CREATED=`exiftool "$file" | grep -m 1 "Create"`

  #extract date and time and reformat
  DATE=`echo $CREATED | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}' | awk -F '[:]' '{print $1"-"$2"-"$3}'`
  TIME=`echo $CREATED | grep -Eo '[0-9]{2}:[0-9]{2}:[0-9]{2}$' | awk -F '[:]' '{print $1"_"$2"_"$3}'`
  
  # read model name and replace spaces with underscore
  MODEL=`exiftool "$file" | grep "Camera Model Name" | cut -d : -f 2 | cut -c 2-30 | tr ' ' '_'`

  # build output file name
  BASE="$DATE $TIME $MODEL"
  
  DIR="$DIR_IN"
  
  debug "DIR_IN $DIR_IN"
  debug "DIR $DIR"
  
  if [ "$ROOT" != "" ] ; then
    debug "Changing root to $ROOT"
    DIR="$ROOT/"
  fi
  
  if [ "$SORT_DIR" == "1" ] ; then
  	 FOLDER=`echo $CREATED | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}' | awk -F '[:]' '{print $1"-"$2}'`
	DIR="$DIR$FOLDER/"
  if [ "$TIME" == "" ] ; then
	DIR="$DIR/NO_METADATA/"	
	fi
  fi

debug "DIR1 $DIR"
 if [ ! -d "$DIR" ] ; then
      debug "Creating directory $DIR"
      mkdir -p "$DIR"
   fi
   
  if [ "$TIME" == "" ] ; then
    debug " NO METADATA !! "

    FILE_IN=`echo $FILE_NAME | sed 's/_NO_METADATA//'`
    debug "OUTPUT $OUTPUT"
  	BASE="$FILE_IN""_NO_METADATA"
  	debug "$OUTPUT"
  fi

   OUTPUT="$DIR$BASE.$EXT"  

POSTFIX=""
MD_IN=`md5 "$file" | awk -F '[=]' '{print $2}'` 

debug "postfix : $POSTFIX"
PROCESSED=0
while [ "$PROCESSED" = 0 ] ; do

MD_OUT=`md5 "$OUTPUT" | awk -F '[=]' '{print $2}'`

# if same file (same md5) exists do nothing
if [ -f "$OUTPUT" ] && [ "$MD_IN" == "$MD_OUT" ] ; then
	log "PICTURE : File $file exists"
	PROCESSED=1
# if file exists, but it's different build a new name (increment)
elif [ -f "$OUTPUT" ] && [ "$MD_IN" != "$MD_OUT" ] ; then
	debug "$OUTPUT"
    POSTFIX=$POSTFIX"_"
    # FIX IT postfix if no metadata
    OUTPUT="$DIR$BASE$POSTFIX.$EXT"
else
	debug "$OUTPUT"
  	debug "$MD_IN"
	debug "$MD_OUT"

	MODIFIED=$(($MODIFIED+1))
	
	if [ "$CP" = 1 ] ; then
	  log "PICTURE : Copying file ($MODIFIED) $file to $OUTPUT"
	  cp "$file" "$OUTPUT"	
	else
	  log "PICTURE : Moving file ($MODIFIED) $file to $OUTPUT"
	  mv "$file" "$OUTPUT"	
	fi
	
	if [ "$ROTATE" = "1" ] ; then
		jhead $OUTPUT
	fi
	
	if [ "$COMPRESS" = "1" ] ; then
		log "PICTURE : Compressing file $OUTPUT"
		convert -compress jpeg -quality 40 $OUTPUT $OUTPUT
	fi 

	PROCESSED=1
fi
done

log " ======================== "
}

while read -d '' -r file; do
    rename "$file"
done < <(find . -type f \( -name "*.jpg" -or -name "*.jpeg" -or -name "*.JPG" \) -print0)

log "MODIF=$MODIFIED"
# count files after
FILES_OUT=`count`

log "Files before processing : $FILES_IN"
log "Files after processing  : $FILES_OUT"
log "Files moved/copied      : $MODIFIED"