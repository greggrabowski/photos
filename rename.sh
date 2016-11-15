#!/bin/bash

# TO DO dependencies, check if installed if not quit with warrning
# TO DO notify about the risk when copying photos
# TO DO change postfix to number
# TO DO search or the files with same md5 (not only those without _ ) 
# TO DO add customized prefix 
# TO DO cleanup functions
# TO DO measure processing time
# TO DO add option to add script to env.
# TO DO option to remove duplicates
# TO DO check system, do nothing if not recognized
# TO DO check if we have all the files if cp (run in safe mode before delete)
# TO DO count files with no metadata and log them, provide stats
# TO DO add option check
# TO DO add metadata to the file
# TO DO add sorting by places, compression, rotation (curl -s $URL | jq -r ".address.city" )
# TO DO add check if file exist (not just run md5 on target file)
# TO DO keep duplicates in dedicated folder
# TO DO select folder for sorted pictures
# TO DO separate script option to update files with metadata
# TO DO format output into table (before/after)
# FIX IT counting files, correct folders, and naming of variables
# TO DO describe criteria for comparison
# reference links
#http://nominatim.openstreetmap.org/reverse.php?format=json&lat=54.36352677857562&lon=18.62155795097351&zoom=
#https://maps.googleapis.com/maps/api/geocode/json?latlng=40.7470444,-073.9411611

# reset counters
COUNTER=0
MODIFIED=0
DUPLICATES=0
KEEP_DUPLICATES=0
 
# Initialize our own variables:
VERBOSE=0
DEBUG=0
LOG_FILE=""
CP=1 
ROTATE=0
COMPRESS=0
SORT=0
RENAME=1
FSIZE=0
FMD5=1

FOLDER=""

BASE_DIR=`pwd`
DIR_OUT=`pwd`
SKIP="qazwsxedcrfv" # unique pattern to skip

function log_ {
    NUM=`echo "${BASH_LINENO[*]}" | cut -f2 -d ' ' `
    DATE=`date "+%Y-%m-%d% %H:%M:%S"`
    LOG_TXT="$DATE : $NUM : $@"
	
	echo -e "$LOG_TXT"
	
	if [ "$LOG_FILE" != "" ] ; then
		echo -e "$LOG_TXT" >> $LOG_FILE
	fi
}   

function nlog {

if [ "$1" == "I" ]; then
  if [ "$VERBOSE" ==  1 ]; then
    log_ "INFO : ${@:2}"
  fi
elif [ "$1" == "D" ]; then
  if [ "$DEBUG" == 1 ] ; then
    log_ "DEBUG : ${@:2}"
  fi
else
  log_ "$@"
fi
}

function log() {
  if [ "$VERBOSE" ==  "1" ] ; then
    log_ "INFO : $@"	
  fi
}

function debug {
	if [ "$DEBUG" = 1 ] ; then
      log_ "DEBUG : $@"
    fi
}  

# ============================= 
function show_help
{
    echo "Usage: rename.sh [-o target_directory] [-d] [-m] [-l log_file] [-r] [-c compression_level] [-x pattern]"
    echo "   -o   copy/move renamed files to target_directory and create directory structure"
    echo "   -d   display debug messages "
    echo "   -m   move files (by default files are copied)"
    echo "   -l   log messages into log_file"
    echo "   -r   automatically rotate files"
    echo "   -c   compress files with compression_level"
    echo "   -s   sort files intro folders (by month)"
    echo "   -x   exclude folders matching pattern"
    echo "   -n   keep original name"
    echo "   -k   keep duplicates in DELETED folder"
    echo "   -f   set matching criteria for duplicates" # FIX IT explain matching criteria
    echo "       m - make of camera"
    echo "       n - name of the model"
    echo "       t - time"
    echo "       h - height"
    echo "       w - width"
    echo "       i - unique ID"
    echo "       c - checksum"
    echo "       s - size"
    echo ""
    echo "Example:"
    echo "./rename.sh -v -d -s -f \"mnt\""
    echo "   -v more logging text"
    echo "   -d debug information"
    echo "   -s sort files into directories representing date (YYYY-MM)"
    echo "   -f compare files based on:"
    echo "      m - camera manufacturer"
    echo "      n - type of the model"
    echo "      t - creation time"
# TO DO -i option (input folder)
    exit 1
}

while getopts "h?c:rmvl:do:sx:nf:k" opt; do
    case "$opt" in
      h|\?)
        show_help
        exit 0 ;;
      c) COMPRESS=$OPTARG ;;
      r) ROTATE=1 ;;
      m) CP=0 ;;
      d) DEBUG=1 ;;
      v) VERBOSE=1 ;;
      l) LOG_FILE=$OPTARG ;;
      s) SORT=1 ;;
      k) KEEP_DUPLICATES=1 ;;
      o) DIR_OUT=$OPTARG ;;
      x) SKIP=$OPTARG ;;
      f) filter_code=`echo $OPTARG | awk '{print toupper($0)}'`
         FMD5=0 
         FSIZE=0;;
      n) RENAME=0 ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

debug "COMPRESS=$COMPRESS"
debug "ROTATE=$ROTATE"
debug "COPY=$CP"
debug "DEBUG=$DEBUG"
debug "LOG_FILE='$LOG_FILE'"
debug "DIR_OUT='$DIR_OUT'"
debug "VERBOSE=$VERBOSE"
debug "SORT=$SORT"
debug "RENAME=$RENAME"
debug "filter_code=$filter_code"
debug "Leftovers: $@"


FILTER=""
#change to upper case
while read -n1 character; do
    #echo "$character"
    APPENDIX=""
    case $character in
		M) APPENDIX="^Make" ;;
		N) APPENDIX="^Camera Model Name" ;;
 		T) APPENDIX="^Create Date  " ;; 	
  		H) APPENDIX="^Image Height" ;;
    	W) APPENDIX="^Image Width" ;;
    	I) APPENDIX="^Image Unique ID" ;;
    	C) FMD5=1 ;;
    	S) FSIZE=1 ;;
		*) APPENDIX="IGNORE" ;;
  esac

if [ "$FILTER" == "" ]; then
  FILTER=$APPENDIX
else
  if [ "$APPENDIX" != "" ]; then
    FILTER="$FILTER\|$APPENDIX"
  fi
fi
done < <(echo -n "$filter_code")

# FIX IT option error check

# ============================= 

function exists {
  T=0

  while [ "$1" != "" ]; do
    type "$1" &> /dev/null ;
    T=$(($T+`echo "$?"`))  
    #echo "Missing tool : $1"  FIX IT - report missing tool
    shift
  done
  echo "$T"
}
    
function count {
c=0
extensions="jpg jpeg mov"
for ext in $extensions; do
  c_=$(find "$1" -maxdepth 10 -iname "*.$ext" -not -path "$SKIP" -print0 | tr -d -c "\000" | wc -c)
  c=$(($c+$c_))
done
echo $c
exit $c
}

function are_same
{
if [ ! -e "$1" ] || [ ! -e "$2" ]; then
  if [ ! -e "$1" ]; then
     log "File (1) $1 doesn't exists"
  fi
  if [ ! -e "$2" ]; then
     log "File (2) $2 doesn't exists"
  fi
  return 0
fi

if [ ! -z "$FILTER" ]; then 
debug "FILTER : $FILTER"

META1=`exiftool "$1" | grep "$FILTER"` | grep -v "Warning"
META2=`exiftool "$2" | grep "$FILTER"` | grep -v "Warning"
 
debug "META1 : $META1"
debug "META2 : $META2"


 if [ "$META1" != "$META2" ]; then
   log "Params of files: $1 | $2 differs"
   return 0
 fi
fi

if [ "$FSIZE" == "1" ]; then
  debug "Comparing size"
  SIZE1=`du "$1" | cut -f1`
  SIZE2=`du "$2" | cut -f1`
  
  
  debug "SIZE1 : $SIZE1"
  debug "SIZE2 : $SIZE2"
  
  if [ "$SIZE1" != "$SIZE2" ]; then
    log "Size of files: $1 | $2 differs"
    return 0
  fi
fi

if [ "$FMD5" == "1" ]; then
debug "Comparing md5"

MD1=`$MD5_CMD "$1" | awk -F '[ ]' '{print $1}'`
MD2=`$MD5_CMD "$2" | awk -F '[ ]' '{print $1}'`

debug "MD1 : $MD1"
debug "MD2 : $MD2"

if [ "$MD1" != "$MD2" ]; then
  log "MD5 of files differs : $MD1 | $MD2"
  return 0
fi


fi

return 1
}


if [[ "$OSTYPE" == "linux-gnu" ]]; then
	log "We are using Linux"
	MD5_CMD="md5sum"
	# check if all tools are installed 
    if [ `exists exiftool md5sum` != 0 ]; then
       log "Not all tools are installed"
     exit
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
	log "We are using MacOS"	
	MD5_CMD="md5 -r"
	# check if all tools are installed 
    if [ `exists exiftool md5` != 0 ]; then
       log "Not all tools are installed"
     exit
    fi
elif [[ "$OSTYPE" == "cygwin" ]]; then
	log "We are using cygwin"
	exit
elif [[ "$OSTYPE" == "win32" ]]; then
	log "We are using windows"
	exit
else
	log "Unrecognized OS"
	exit
fi


# count files before
FILES_IN=`count "$BASE_DIR"` 
SIZE_IN=`du -hs "$BASE_DIR" | cut -f1`
START=`date +%s`

log "BASE_DIR=$BASE_DIR"


function rename {
  
file=$1

# take action on each file. $f store current file name  
COUNTER=$(($COUNTER + 1))
log "Processing file $file ($COUNTER/$FILES_IN)"

# get directory
DIR_IN=`echo "$file" | grep -Eo '.*[/]'`
  
# get file extension
EXT=${file##*.}
  
# get short file name (no extension) 
FILE_NAME_IN=`echo "$file" | rev | cut -d / -f 1 | sed 's/^[^.]*.//g' | rev`
   
# read creation time from metadata
CREATED=`exiftool "$file" | grep -m 1 "Create"`

#extract date and time and reformat
DATE=`echo $CREATED | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}' | awk -F '[:]' '{print $1"-"$2"-"$3}'`
TIME=`echo $CREATED | grep -Eo '[0-9]{2}:[0-9]{2}:[0-9]{2}$' | awk -F '[:]' '{print $1"_"$2"_"$3}'`
  
# read model name and replace spaces with underscore
MODEL=`exiftool "$file" | grep "Camera Model Name" | cut -d : -f 2 | cut -c 2-30 | tr ' ' '_'`

# build output file name
if [ "$RENAME" = 1 ]; then
  if [ "$TIME" == "" ] ; then
    debug " NO METADATA in file $file !! "
    FILE_NAME_OUT=`echo "$FILE_NAME_IN" | sed 's/_NO_METADATA//'`
else
    FILE_NAME_OUT="$DATE $TIME $MODEL"
fi
else
  # keep original name
  FILE_NAME_OUT=$FILE_NAME_IN
fi
  
debug "FILE_NAME_IN  : $FILE_NAME_IN"
debug "FILE_NAME_OUT : $FILE_NAME_OUT"
      
DIR="$DIR_IN"
  
debug "DIR_IN $DIR_IN"
debug "DIR $DIR"
  
if [ "$SORT" == "1" ] ; then
	debug "Sorting photos into folders"

	if [ "$TIME" == "" ] ; then
		FOLDER="NO_METADATA"	
	else
		FOLDER=`echo $CREATED | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}' | awk -F '[:]' '{print $1"-"$2}'`
	fi

	DIR="$DIR_OUT/SORTED/$FOLDER/"
else
	
	debug "DIR IN = $DIR_IN"
	debug "DIR OUT = $DIR_OUT"
	x=`echo $BASE_DIR | wc -c`
	x=$((x+1))
	FOLDER=`echo $DIR_IN | cut -c $x-`
	debug "FOLDER : $FOLDER"
	DIR="$DIR_OUT/$FOLDER"
fi
 	
if [ ! -d "$DIR" ] ; then
	debug "Creating directory $DIR"
	mkdir -p "$DIR"
fi

OUTPUT="$DIR$FILE_NAME_OUT.$EXT"
debug "OUTPUT <- $OUTPUT"  

POSTFIX=""
#MD_IN=`$MD5_CMD "$file" | awk -F '[ ]' '{print $1}'` # FIX IT change it to function 

debug "postfix : $POSTFIX"
PROCESSED=0
while [ "$PROCESSED" = 0 ] ; do

#MD_OUT=`$MD5_CMD "$OUTPUT" | awk -F '[ ]' '{print $1}'`


debug "IN  : $MD_IN :$file"
debug "OUT : $MD_OUT : $OUTPUT"

are_same "$file" "$OUTPUT"
same_files=$?
	
debug "same_files = $same_files"

if [ ! -f "$OUTPUT" ]; then
	debug "$OUTPUT"
  	debug "$MD_IN"
	debug "$MD_OUT"

	MODIFIED=$(($MODIFIED+1))
	
	if [ "$CP" == 1 ] ; then
		log "PICTURE : Copying file ($MODIFIED) $file to $OUTPUT"
		cp "$file" "$OUTPUT"	
	else
		log "PICTURE : Moving file ($MODIFIED) $file to $OUTPUT"
	  	mv "$file" "$OUTPUT"	
	fi
	PROCESSED=1
else
  if [ $same_files -eq 1 ]; then
log "PICTURE : Duplicates found: $file | $OUTPUT" # FIX IT log source and destination file
DUPLICATES=$(($DUPLICATES+1))
	# if same file (same md5) exists do nothing
	if [ "$file" != "$OUTPUT" ]; then
		
		if [ "$CP" == 0 ] ; then
		  if [ "$KEEP_DUPLICATES" == 0 ]; then
		    log "Deleting duplicate $file"
		    rm -f "$file"
		  else
		    log "Moving duplicate $file"
		    # FIX IT move file
		    # mv "$file" "$OUTPUT"  
		  fi
		fi
	fi
	PROCESSED=1
  else
  # if file exists, but it's different build a new name (increment)
  	debug "Need to add prefix to $OUTPUT"
    POSTFIX=$POSTFIX"_"
    # FIX IT postfix if no metadata
    OUTPUT="$DIR$FILE_NAME_OUT$POSTFIX.$EXT"
  fi
fi

done

log " ================================= "
}

while read -d '' -r file; do
	# FIX IT
	if [ "$ROTATE" = "1" ] ; then
		jhead $file
	fi
	# FIX IT
	if [ "$COMPRESS" -gt "0" ] ; then
		log "PICTURE : Compressing (quality set to $COMPRESS%) file : $file"
		convert -compress jpeg -quality "$COMPRESS" "$file" "$file"
	fi 
	if [ "$RENAME" = "1" ]; then
	   rename "$file"
	fi
done < <(find "$BASE_DIR" -type f \( -iname "*.jpg" -or -iname "*.jpeg" -or -iname "*.mov" \) -not -path "$SKIP" -print0)

log "MODIF=$MODIFIED"
# count files after
FILES_OUT=`count "$DIR_OUT"`
SIZE_OUT=`du -hs "$DIR_OUT" | cut -f1`
END=`date +%s`

secs=$(($END-$START))
TIME=`printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))`

SS=`date -r $START`
EE=`date -r $END`

log_ "Start: $SS, End: $EE"

log_ "Processing time : $TIME"
log_ "Files before processing in $BASE_DIR : $FILES_IN"
log_ "Files after processing in $DIR_OUT   : $FILES_OUT"
log_ "Size of $BASE_DIR before processing : $SIZE_IN"
log_ "Size of $DIR_OUT after processing   : $SIZE_OUT"
log_ "Files moved/copied      : $MODIFIED"
log_ "Duplicates              : $DUPLICATES"