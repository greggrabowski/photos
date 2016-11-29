#!/bin/bash

# TO DO look for duplicates and remove them
# TO DO dependencies, check if installed if not quit with warrning
# TO DO notify about the risk when copying photos
# TO DO change postfix to number
# TO DO search or the files with same md5 (not only those without _ ) 
# TO DO add customized prefix 
# TO DO cleanup functions
# TO DO measure processing time
# TO DO add option to add script to env.
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
# reference links
#http://nominatim.openstreetmap.org/reverse.php?format=json&lat=54.36352677857562&lon=18.62155795097351&zoom=
#https://maps.googleapis.com/maps/api/geocode/json?latlng=40.7470444,-073.9411611
#exiftool . | grep "GPS Pos" | sed "s/GPS Position //g; s/deg/|/g; s/[,':]/|/g; s/'\ '//g; s/N/|N/g; s/S/|S/g; s/E/|E/g; s/W/|W/g" | awk  -F "\|" '{lat=$2+$3/60+4/3600; lon=$6+$7/60+8/3600; if ($5 == "S") lat=-lat; if ($9 == "W") lon=-lon; printf("http://nominatim.openstreetmap.org/reverse.php?format=json&lat=%.4f&lon=%.4f\n",lat,lon)}' 
#echo "$GPS" | sed "s/GPS Position //g; s/deg/|/g; s/[,':]/|/g; s/'\ '//g; s/N/|N/g; s/S/|S/g; s/E/|E/g; s/W/|W/g" | awk  -F "\|" '{lat=$2+$3/60+4/3600; lon=$6+$7/60+8/3600; if ($5 == "S") lat=-lat; if ($10 == "W") lon=-lon; printf("%.4f\n%.4f\n",lat,lon)}' 
#curl `exiftool . | grep "GPS Pos" | sed "s/GPS Position //g; s/deg/|/g; s/[,':]/|/g; s/'\ '//g; s/N/|N/g; s/S/|S/g; s/E/|E/g; s/W/|W/g" | awk  -F "\|" '{lat=$2+$3/60+4/3600; lon=$6+$7/60+8/3600; if ($5 == "S") lat=-lat; if ($9 == "W") lon=-lon; printf("http://nominatim.openstreetmap.org/reverse.php?format=json&lat=%.4f&lon=%.4f\n",lat,lon)}'` | jq -r ".address"
#exiftool "DSC_0136 (2).JPG" | grep "Latitude  " | sed -E "s/.*:|\'|\"//g" | awk '{print $1" "  $3" " $4}'
# TO DO add recommended option -a (~/Documents/repos/photos/rename.sh -m -s -d -v -k -x "*thumb*" -l "rename.log" -o "/share/Multimedia/my_photos")
# TO DO add metadata updater, folder vs file name check
# TO DO add png processing, files selection
# TO DO detailed statistics about files
# TO DO show left files
# TO file stats before/after in each folder
# TO DO add date to log file name
# TO DO display progress only in one line \r
# TO DO warning for non root users
# TO DO smarter dependencies check (based on the selection)
# TO DO keeping duplicates in folders
# TO DO copy original files/backup before processing
# TO DO add long options

#read -p "Continue (y/n)?" CONT
#read -p "Are you sure? " -n 1 -r
#echo    # (optional) move to a new line
#if [[ $REPLY =~ ^[Yy]$ ]]
#then
    # run command
#fi

#f [[ $EUID -ne 0 ]]; then

# reset counters
COUNTER=0
MODIFIED=0
DUPLICATES=0
KEEP_DUPLICATES=0
 
# Initialize  variables:
VERBOSE=0
DEBUG=0
LOG_FILE=""
CP=1 
ROTATE=0
COMPRESS=0
SORT=0
RENAME=1
DIRO=0;
FSIZE=0
FMD5=1
FMAE=0
ONE_LEVEL=0
UPDATE_GEO=0
JPG=0
UPDATE_TIME=0
CHECK_DUPLICATES=0
REF_FOLDER=""
FOLDER=""
TEST_RUN=0
KEEP_BIGGER=0
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

function log_i() {
    log_ "INFO : $@"	
}

function log_v() {
  if [ "$VERBOSE" ==  "1" ] ; then
    log_ "INFO : $@"	
  fi
}

function log_d {
	if [ "$DEBUG" = 1 ] ; then
      log_ "DEBUG : $@"
    fi
}  

# ============================= 
function show_help
{
    echo "Usage: rename.sh [-o target_directory] [-d] [-m] [-b] [-l log_file] [-r] \
         [-c compression_level] [-x pattern] [-1] [k] [j] [t] [-z ref_folder] [-g]"
    echo "   -o   copy/move renamed files to target_directory and create directory structure"
    echo "   -d   display debug messages "
    echo "   -m   move files (by default files are copied)"
    echo "   -b   keep bigger file if same/similar files found"
    echo "   -l   log messages into log_file"
    echo "   -r   automatically rotate files"
    echo "   -c   compress filartes with compression_level"
    echo "   -s   sort files intro folders (by month)"
    echo "   -x   exclude folders matching pattern"
    echo "   -n   keep original name"
    echo "   -j   change all the jpg,jpeg and JPG extension to jpg"
    echo "   -k   keep duplicates in orignal/source folder"
    echo "   -1   when sorting into output directory don't recreate the whole directory structure, include only directory where original file is located"
    echo "   -t   test run"
    echo "   -u   update time in metadata based on the folder name"
    echo "   -z   look for duplicate in ref_folder if found delete source file"
    echo "   -g   update metadata comment using geolocation (coutry, city, etc)" 
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
    echo "      w - image width"
    echo "      h - image height"
    echo "      i - image ID"
    echo "      c - checksum (MD5)"
    echo "      s - file size"
    echo "      x - mean absolute error (normalized), average channel error distance"
# TO DO -i option (input folder)
    exit 1
}
    	
while getopts "1bc:df:ghjkl:mno:rstuvx:z:?" opt; do
    case "$opt" in
      h|\?)
        show_help
        exit 0 ;;
      c) COMPRESS=$OPTARG ;;
      r) ROTATE=1 ;;
      m) CP=0 ;;
      b) KEEP_BIGGER=1 ;;
      d) DEBUG=1 ;;
      v) VERBOSE=1 ;;
      l) LOG_FILE=$OPTARG ;;
      s) SORT=1 ;;
      k) KEEP_DUPLICATES=1 ;;
      o) DIRO=1;
         DIR_OUT=$OPTARG ;;
      x) SKIP=$OPTARG ;;
      j) JPG=1 ;;
      g) UPDATE_GEO=1 ;;
      f) filter_code=`echo $OPTARG | awk '{print toupper($0)}'`
         FMD5=0 
         FSIZE=0;;
      n) RENAME=0 ;;
      u) UPDATE_TIME=1 ;;
      1) ONE_LEVEL=1 ;;
      t) TEST_RUN=1 ;;
      z) CHECK_DUPLICATES=1
		 REF_FOLDER=$OPTARG ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

log_d "COMPRESS=$COMPRESS"
log_d "ROTATE=$ROTATE"
log_d "KEEP_BIGGER=$KEEP_BIGGER"
log_d "COPY=$CP"
log_d "DEBUG=$DEBUG"
log_d "LOG_FILE='$LOG_FILE'"
log_d "DIR_OUT='$DIR_OUT'"
log_d "VERBOSE=$VERBOSE"
log_d "SORT=$SORT"
log_d "RENAME=$RENAME"
log_d "filter_code=$filter_code"
log_d "one level=$ONE_LEVEL"
log_d "test run=$TEST_RUN"
log_d "DIRO=$DIRO"
log_d "JPG=$JPG"
log_d "UPDATE_GEO=$UPDATE_GEO"
log_d "UPDATE_TIME=$UPDATE_TIME"
log_d "CHECK_DUPLICATES=$CHECK_DUPLICATES, REF_FOLDER=$REF_FOLDER"
log_d "Leftovers: $@"

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
    	X) FMAE=1 ;;
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
extensions="jpg jpeg mov mp4 png gif m4a"
for ext in $extensions; do
  c_=$(find "$1" -maxdepth 10 -iname "*.$ext" -not -path "$SKIP" -print0 \
     | tr -d -c "\000" | wc -c)
  c=$(($c+$c_))
done
echo $c
exit $c
}

function are_same
{
if [ ! -e "$1" ] || [ ! -e "$2" ]; then
  if [ ! -e "$1" ]; then
     log_v "File (1) $1 doesn't exists"
  fi
  if [ ! -e "$2" ]; then
     log_v "File (2) $2 doesn't exists"
  fi
  return 0
fi

if [ ! -z "$FILTER" ]; then 
log_d "FILTER : $FILTER"

META1=`exiftool "$1" | grep "$FILTER"` | grep -v "Warning"
META2=`exiftool "$2" | grep "$FILTER"` | grep -v "Warning"
 
log_d "META1 : $META1"
log_d "META2 : $META2"


 if [ "$META1" != "$META2" ]; then
   log_v "Params of files: $1 | $2 differs"
   return 0
 fi
fi

if [ "$FSIZE" == "1" ]; then
  log_d "Comparing size"
  SIZE1=`du "$1" | cut -f1`
  SIZE2=`du "$2" | cut -f1`
  
  
  log_d "SIZE1 : $SIZE1"
  log_d "SIZE2 : $SIZE2"
  
  if [ "$SIZE1" != "$SIZE2" ]; then
    log_v "Size of files: $1 | $2 differs"
    return 0
  fi
fi

if [ "$FMD5" == "1" ]; then
log_d "Comparing md5"

MD1=`$MD5_CMD "$1" | awk -F '[ ]' '{print $1}'`
MD2=`$MD5_CMD "$2" | awk -F '[ ]' '{print $1}'`

log_d "MD1 : $MD1"
log_d "MD2 : $MD2"

if [ "$MD1" != "$MD2" ]; then
  log_v "MD5 of files differs : $MD1 | $MD2"
  return 0
fi

fi

# FIX IT do it only for jpg
# FIX IT handle errors
if [ "$FMAE" == "1" ]; then
if [ "$EXT1" == "JPG" ] || [ "$EXT1" == "jpeg"  ] || [ "$EXT1" == "JPEG" ]; then
MAE=`compare -metric MAE "$1" "$2" null: 2>&1 | \
    awk '{print $2}' | sed -E "s/\(|\)//g"`

THRESHOLD=0.01
if (( $(bc <<< "$MAE > $THRESHOLD") )) ; then
  log_v "MAE ($MAE) > THRESHOLD ($THRESHOLD)"
  return 0
fi
fi
fi
#compare -metric MAE 1.jpg 1compressed20.jpg null: 2>&1 | awk '{print $2}' | sed -E "s/\(|\)//g"

return 1
}


if [[ "$OSTYPE" == "linux-gnu" ]]; then
	log_v "We are using Linux"
	MD5_CMD="md5sum"
	# check if all tools are installed 
    if [ `exists exiftool md5sum date awk sed compare convert` != 0 ]; then
       log_v "Not all tools are installed"
     exit
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
	log_v "We are using MacOS"	
	MD5_CMD="md5 -r"
	# check if all tools are installed 
    if [ `exists exiftool md5 date awk sed compare convert` != 0 ]; then
       log_v "Not all tools are installed"
     exit
    fi
elif [[ "$OSTYPE" == "cygwin" ]]; then
	log_v "We are using cygwin"
	exit
elif [[ "$OSTYPE" == "win32" ]]; then
	log_v "We are using windows"
	exit
else
	log_v "Unrecognized OS"
	exit
fi

if [ ! -d "$DIR_OUT" ] ; then
	log_i "Creating directory $DIR_OUT"
	if [ "$TEST_RUN" != 1 ]; then
	  mkdir -p "$DIR_OUT"
	fi
fi

# count files before
FILES_IN_1=`count "$BASE_DIR"` 
SIZE_IN_1=`du -hs "$BASE_DIR" | cut -f1`
FILES_OUT_1=`count "$DIR_OUT"` 
SIZE_OUT_1=`du -hs "$DIR_OUT" | cut -f1`


START=`date +%s`
SS=`date`

log_v "BASE_DIR=$BASE_DIR"

function update_comments {
# get GPS position and extract latitude and longitude
LAT_TXT=`exiftool "$1" | grep "Latitude  " | sed -E "s/.*:|\'|\"//g"`
LON_TXT=`exiftool "$1" | grep "Longitude  " | sed -E "s/.*:|\'|\"//g"`
LAT=`echo "$LAT_TXT" | awk '{lat=$1+$3/60+4/3600; if ($5 == "S") lat=-lat; printf("%.4f",lat)}'`
LON=`echo "$LON_TXT" | awk '{lon=$1+$3/60+4/3600; if ($5 == "W") lon=-lon; printf("%.4f",lon)}'`

# get geo-location
GLINK="http://nominatim.openstreetmap.org/reverse.php?format=json&lat=$LAT&lon=$LON"

# prepare the comments
GEODATA=`curl --connect-timeout 3 -s "$GLINK"`
COUNTRY=`echo $GEODATA | jq '.address.country'`
COUNTY=`echo $GEODATA | jq '.address.county'`
CITY=`echo $GEODATA | jq '.address.city'`
ROAD=`echo $GEODATA | jq '.address.road'`

COMMENT=''
if [ "$COUNTRY" != "null" ]; then
  COMMENT="Country: $COUNTRY; "
fi
if [ "$COUNTY" != "null" ]; then
  COMMENT="$COMMENT""County: $COUNTY; "
fi
if [ "$CITY" != "null" ]; then
  COMMENT="$COMMENT""City: $CITY; "
fi
if [ "$ROAD" != "null" ]; then
  COMMENT="$COMMENT""Road: $ROAD; "
fi
if [ ! -z "$COMMENT" ]; then
		  log_v "Updating comments in $file to :\n $COMMENT"
		  if [ "$TEST_RUN" != 1 ]; then
	  	    exiftool -q -comment="$COMMENT" "$1" -overwrite_original
	  	  fi
	  	  fi
}

function rename {
  
file=$1

# get directory
DIR_IN=`echo "$file" | grep -Eo '.*[/]'`
  
# get file extension
EXT1=${file##*.}

EXT=$EXT1
if [ "$JPG" == 1 ]; then
  if [ "$EXT1" == "JPG" ] || [ "$EXT1" == "jpeg"  ] || [ "$EXT1" == "JPEG" ]; then
  	EXT="jpg"
  fi
fi 
  
# get short file name (no extension) 
FILE_NAME_IN=`echo "$file" | rev | cut -d / -f 1 | sed 's/^[^.]*.//g' | rev`
   
# read creation time from metadata
CREATED=`exiftool "$file" | grep -m 1 "^Create"`

if [ -z "$CREATED" ]; then
  CREATED=`exiftool "$file" | grep -m 1 "^Date Created"`
fi

#extract date and time and reformat
DATE=`echo $CREATED | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}' \
     | awk -F '[:]' '{print $1"-"$2"-"$3}'`
TIME=`echo $CREATED | grep -Eo '[0-9]{2}:[0-9]{2}:[0-9]{2}$' \
     | awk -F '[:]' '{print $1"_"$2"_"$3}'`  

# read model name and replace spaces with underscore
MODEL=`exiftool "$file" | grep "Camera Model Name" | cut -d : -f 2 \
      | cut -c 2-30 | tr ' ' '_'`


# build output file name
if [ "$RENAME" == 1 ]; then
  if [ "$TIME" == "" ] ; then
    log_d " NO METADATA in file $file !! "
    FILE_NAME_OUT=`echo "$FILE_NAME_IN" | sed 's/_NO_METADATA//'`
  else
    if [ -z "$MODEL" ] ;then
      FILE_NAME_OUT="$DATE $TIME"
    else
      FILE_NAME_OUT="$DATE $TIME $MODEL"
    fi
  fi
else
  # keep original name
  FILE_NAME_OUT=$FILE_NAME_IN
fi
  
log_d "FILE_NAME_IN  : $FILE_NAME_IN"
log_d "FILE_NAME_OUT : $FILE_NAME_OUT"
      
DIR="$DIR_IN"
  
log_d "DIR_IN $DIR_IN"
log_d "DIR $DIR"
 
#check if file doesn't exist
if [ "$CHECK_DUPLICATES" == 1 ]; then
  YY_MM=`echo "$DATE" | cut -c -7`

    #are_same "$file" "$OUTPUT"
    while read -d '' -r filex; do
      log_v "Found similar in $filex"
      are_same "$file" "$filex"
      duplicates=$?
      
       if [ $duplicates -eq 1 ]; then
         log_v "Found duplicate in ref folder : $file | $filex"
         
		 if [ "$KEEP_DUPLICATES" == 0 ]; then
		    
		    if [ "$file" != "$filex" ]; then
		      log_v "Deleting duplicate $file"
		      if [ "$TEST_RUN" != 1 ]; then
		        rm -f "$file"
		      fi
		    fi
		fi

         
       fi
    done < <(find "$REF_FOLDER" -path "*$YY_MM*" -type f \
                  -iname "$FILE_NAME_OUT.$EXT" -print0)
fi
  
if [ "$SORT" == "1" ] ; then
	if [ "$TIME" == "" ] ; then
		FOLDER="NO_METADATA"	
	else
		FOLDER=`echo $CREATED | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}' \
		       | awk -F '[:]' '{print $1"-"$2}'`
	fi
	if [ "$DIRO" == 1 ]; then
	  DIR="$DIR_OUT/$FOLDER/"
	else
	  DIR="$DIR_OUT/SORTED/$FOLDER/"
	fi
else
	log_d "DIR IN = $DIR_IN"
	log_d "DIR OUT = $DIR_OUT"
	if [ "$ONE_LEVEL" == "1" ] ; then
	  #LAST_DIR=echo "$pathname" |  rev |  awk -F '[/]' '{print $2}'
	  FOLDER=`echo "$file" | rev |  awk -F '[/]' '{print $2}' | rev`
	  FOLDER="$FOLDER/"
	else
	  x=`echo $BASE_DIR | wc -c`
	  x=$((x+1))
	  FOLDER=`echo $DIR_IN | cut -c $x-`
	fi
	log_d "FOLDER : $FOLDER"
	DIR="$DIR_OUT/$FOLDER"
fi
 	
if [ ! -d "$DIR" ] ; then
	log_d "Creating directory $DIR"
	if [ "$TEST_RUN" != 1 ]; then
	  mkdir -p "$DIR"
	fi
fi

OUTPUT="$DIR$FILE_NAME_OUT.$EXT"
log_d "OUTPUT <- $OUTPUT"  

POSTFIX="" 

log_d "postfix : $POSTFIX"
PROCESSED=0
while [ "$PROCESSED" = 0 ] ; do

log_d "IN  : $MD_IN :$file"
log_d "OUT : $MD_OUT : $OUTPUT"

are_same "$file" "$OUTPUT"
same_files=$?
	
log_d "same_files = $same_files"

if [ ! -f "$OUTPUT" ]; then

	MODIFIED=$(($MODIFIED+1))
	
	if [ "$CP" == 1 ] ; then
		log_v "PICTURE : Copying file ($MODIFIED) $file to $OUTPUT"
		if [ "$TEST_RUN" != 1 ]; then
		   cp "$file" "$OUTPUT"	
		fi
	else
		log_v "PICTURE : Moving file ($MODIFIED) $file to $OUTPUT"
	  	if [ "$TEST_RUN" != 1 ]; then
	  	  mv "$file" "$OUTPUT"
	  	fi	
	fi
	PROCESSED=1
else
  if [ $same_files -eq 1 ]; then
log_v "PICTURE : Duplicates found: $file | $OUTPUT"
DUPLICATES=$(($DUPLICATES+1))
	# if same file (same md5) exists do nothing
	if [ "$file" != "$OUTPUT" ]; then
		
		if [ "$CP" == 0 ] ; then
		  if [ "$KEEP_DUPLICATES" == 0 ]; then
		    log_v "Deleting duplicate $file"

		    if [ "$TEST_RUN" != 1 ]; then

		      if [ "$KEEP_BIGGER" == "1" ]; then
			    SIZE_FILE=`du "$file" | awk '{print $1}'`
		        SIZE_OUTPUT=`du "$OUTPUT" | awk '{print $1}'`
		        if (( $(bc <<< "$SIZE_FILE > $SIZE_OUTPUT") )) ; then
		          mv -f "$file" "$OUTPUT"
		        else
		          rm -f "$file"
		        fi
		      else 
		        rm -f "$file"
		      fi
		    fi
		  else
		    log_v "Leaving duplicate $file"
		    # FIX IT move file
		    # mv "$file" "$OUTPUT"  
		  fi
		fi
	fi
	PROCESSED=1
  else
  # if file exists, but it's different build a new name (increment)
  	log_d "Need to add prefix to $OUTPUT"
    POSTFIX=$POSTFIX"_"
    # FIX IT postfix if no metadata
    OUTPUT="$DIR$FILE_NAME_OUT$POSTFIX.$EXT"
  fi
fi

done

log_v " ================================= "
}

if [ "$SORT" == "1" ] ; then
	log_d "Sorting photos into folders"
fi


STEP=$(($FILES_IN_1 / 100))
if [ "$STEP" == 0 ]; then
  STEP=1
fi

# ========================== MAIN LOOP =============================

while read -d '' -r file; do
#log_i "Starting ...."
# take action on each file. $f store current file name  
MOD=$(($COUNTER%$STEP))
if [ "$MOD" == 0 ]; then
  #echo -ne "\r"
  # count real progress here
  PROGRESS=$((100*$COUNTER/$FILES_IN_1))
  log_i "Progress : $PROGRESS% : ($COUNTER/$FILES_IN_1)"
fi

COUNTER=$(($COUNTER + 1))

log_v "Processing file $file ($COUNTER/$FILES_IN_1)"

	# FIX IT
	if [ "$UPDATE_GEO" == "1" ] ; then
		update_comments "$file"
	fi


	if [ "$UPDATE_TIME" == "1" ]; then
	  # get folder name
	  # FIX IT read metadata first and update / or update in empty
	  FOLDER_DATE=`echo "$file" | rev |  awk -F '[/]' '{print $2}' | rev | cut -c -8`
	  # check if folder has format YYYY-MM
	  
	  if [[ "$FOLDER_DATE " =~ [0-9]{4}-[0-9]{2}[" "] ]]; then
		  # convert folder time to epoch
		  echo "Updating $FOLDER_DATE $file"
		  FOLDER_EPOCH=`date -j -f "%Y-%m-%d %H:%M:%S" "${FOLDER_DATE:0:7}-01 00:00:01" "+%s"`
		  #get start date and add counter 
		  NEW_DATE=$(($FOLDER_EPOCH + $COUNTER))
		  # convert epoch to time and date
		  META_DATE=`date -r "$NEW_DATE" +'%Y-%m-%d %H:%M:%S'`
		  log_v "Updating time in file $file to $META_DATE"
		  if [ "$TEST_RUN" != 1 ]; then
	  	    exiftool -q -createdate="$META_DATE" "$file" -overwrite_original
	  	  fi
	  fi
	fi

	# FIX IT
	if [ "$ROTATE" == "1" ] ; then
		jhead $file
	fi
	# FIX IT
	if [ "$COMPRESS" -gt "0" ] ; then
		log_v "PICTURE : Compressing (quality set to $COMPRESS%) file : $file"
		convert -compress jpeg -quality "$COMPRESS" "$file" "$file"
	fi 
	if [ "$RENAME" == "1" ]; then
	   rename "$file"
	fi
done < <(find "$BASE_DIR" -type f \( -iname "*.jpg" -or -iname "*.jpeg" -or \
  -iname "*.mov" -or -iname "*.png" -or -iname "*.mp4" -or -iname "*.gif" \
  -or -iname "*.m4a" \) -not -path "$SKIP" -print0)

# ======================= END OF MAIN LOOP =============================

log_d "MODIF=$MODIFIED"
# count files after
FILES_IN_2=`count "$BASE_DIR"` 
SIZE_IN_2=`du -hs "$BASE_DIR" | cut -f1`
FILES_OUT_2=`count "$DIR_OUT"`
SIZE_OUT_2=`du -hs "$DIR_OUT" | cut -f1`


END=`date +%s`

secs=$(($END-$START))
TIME=`printf '%02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))`


EE=`date`

log_i "Start: $SS, End: $EE"
log_i "Processing time : $TIME"

log_i " ****************************"
log_i " ********** BEFORE **********"
log_i " ****************************"

log_i "Source directory : $BASE_DIR : files=$FILES_IN_1 : $SIZE_IN_1"
log_i "Target directory : $DIR_OUT : files=$FILES_OUT_1 : $SIZE_OUT_1"

log_i " ****************************"
log_i " ********** AFTER ***********"
log_i " ****************************"

log_i "Source directory : $BASE_DIR : files=$FILES_IN_2 : $SIZE_IN_2"
log_i "Target directory : $DIR_OUT : files=$FILES_OUT_2 : $SIZE_OUT_2"

log_i "Files moved/copied      : $MODIFIED"
log_i "Duplicates              : $DUPLICATES"