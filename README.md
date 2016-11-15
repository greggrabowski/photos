# photos
Bunch of scripts to manage pictures

============ rename.sh ============

This script reads file representing photos and create new files based on the file metadata.
The name reflects creation date, time and camera model, which might be useful to find duplicates and sort files.
An examples of renamed file below:
- 2015-06-28 12_44_21 Canon_EOS_5D_Mark_III.jpg
- 2016-05-22 15_49_57 D5803.jpg

Additionally files might be sorted into folders representing year and date (-s option).
Below an example of directory structure with the destination folders.

SORTED<BR/>
|<BR/>
|---2015-06
|<BR/>
|---2016-01
|<BR/>
|---2016-02
|<BR/>
|---NO_METADATA

Files are copied or moved (-m option) based on creation date stored in metadata. If there is no metadata files are copeid/moved into NO_METADATA directory.
Duplicates are discovered using md5 checksum. If file with same name exist in destnation folder, but it has different md5, a postfix is added to the file name.

   test

Usage:
`rename.sh [-o target_directory] [-d] [-m] [-l log_file] [-r] [-c compression_level] [-s] [-x pattern] [-n] [-k] [-f "mnthwics"]`
   -o   copy/move renamed files to target_directory and create directory structure
   -d   display debug messages
   -m   move files (by default files are copied)
   -l   log messages into log_file
   -r   automatically rotate files
   -c   compress files with compression_level
   -s   sort files intro folders (by month)
   -x   exclude folders matching pattern
   -n   keep original name
   -k   keep duplicates in DELETED folder
   -f   set matching criteria for duplicates
       m - make of camera
       n - name of the model
       t - time
       h - height
       w - width
       i - unique ID
       c - checksum
       s - size
<BR/>
   **Example**:

 ./rename.sh -v -d -s -f \"mnt\"

      -v more logging text
      -d debug information
      -s sort files into directories representing date (YYYY-MM)
      -f compare files based on:
         m - camera manufacturer
         n - type of the model
         t - creation time
