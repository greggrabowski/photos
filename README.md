# photos
Bunch of scripts to manage pictures

============ rename.sh ============

This script reads file representing photos and create new files based on the file metadata.
The name reflects creation date, time and camera model, which might be useful to find duplicates and sort files.
An examples of renamed file below:<br />
2015-06-28 12_44_21 Canon_EOS_5D_Mark_III.jpg<br \>
2016-05-22 15_49_57 D5803.jpg<br \>

Additionally files might be sorted into folders representing year and date (-s option).
Below an example of directory structure with the destination folders.

SORTED<br />
|<br />
---2015-06<br />
|<br />
---2016-01<br />
|<br />
---2016-02<br />
|<br />
---NO_METADATA<br />

Files are copied or moved (-m option) based on creation date stored in metadata. If there is no metadata files are copeid/moved into NO_METADATA directory.
Duplicates are discovered using md5 checksum. If file with same name exist in destnation folder, but it has different md5, a postfix is added to the file name.

Usage: rename.sh [-o target_directory] [-d] [-m] [-l log_file] [-r] [-c compression_level]<br />
   -o   copy/move renamed files to target_directory and create directory structure<br />
   -d   display debug messages<br />
   -m   move files (by default files are copied)<br />
   -l   log messages into log_file<br />
   -r   automatically rotate files<br />
   -c   compress files with compression_level<br />
   -s   sort files intro folders (by month)<br />
   -x   exclude folders matching pattern<br />
   -n   keep original name<br />
   -k   keep duplicates in DELETED folder<br />
   -f   set matching criteria for duplicates" # FIX IT explain matching criteria<br />
       m - make of camera<br />
       n - name of the model<br />
       t - time<br />
       h - height<br />
       w - width<br />
       i - unique ID<br />
       c - checksum<br />
       s - size<br />
<br />   
   Example:<br />
   ./rename.sh -v -d -s -f \"mnt\"<br />
      -v more logging text<br />
      -d debug information<br />
      -s sort files into directories representing date (YYYY-MM)<br />
      -f compare files based on:<br />
         m - camera manufacturer<br />
         n - type of the model<br />
         t - creation time<br />