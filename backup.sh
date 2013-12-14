#!/bin/bash
# ================================================================================
# backup.sh
# 
# A fancy little shell script that backs up your webroot and MySQL databases to Amazon AWS S3.
#
# You must have s3cmd installed on your system. 
# See: https://kura.io/2012/02/29/backup-a-linux-server-to-amazon-s3-on-debian-6ubuntu-10-04/
# 
# ======= CONFIGURATION ========
# 
# Amazon S3 Bucket Name
# 
# S3_BUCKET_NAME="bucket-name"
# 
  S3_BUCKET_NAME="BUCKET-NAME"
# 
# Amazon S3 Directory Path
# Leave this blank if you are putting it in your root directory
# 
# S3_SQL_PATH="/path/to/directory"
# 
  S3_SQL_PATH=""
#
# Amazon S3 Web Files Path
#
# S3_WEB_PATH="/path/to/directoy"
#
  S3_WEB_PATH=""
# 
# MySQL User
# 
# MYSQL_USER="root"
# 
  MYSQL_USER=""
# 
# MySQL Password
# 
# MYSQL_PASSWD="sekret"
# 
  MYSQL_PASSWD=""
# 
# MySQL Host
# 
# MYSQL_HOST="localhost"
# 
  MYSQL_HOST=""
# 
# Webroot directory
# 
# Folders (sites) in this directory will get compressed and
# uploaded to your AWS S3 account
# 
# WEB_ROOT="/var/www"
# 
  WEB_ROOT=""
# 
# Backup Directory
# 
# Local directory to work from, if you are not storing your
# backups locally you can just use the tmp directory or
# set it to the directory this shell script is in.
# 
# BACKUP_DIR="/backup"
#
  BACKUP_DIR=""
#
# Would you like to store the files locally?
# 
# KEEP_LOCAL=true/false
#
  KEEP_LOCAL=true
#
# Local storage directory
# 
# You will need the full path to the directory
# 
# STORAGE_DIR="/backup/storage"
#
  STORAGE_DIR=""
#
# How many days do you want to store the local files?
# This should be in days. Files older than this many days will be deleted
# 
# KEEP_UNTIL=30
#
  KEEP_UNTIL=30  
#
# Log file
# 
# This needs to be the full path of the log file included
# or any log file you'd like to write to.
# 
# LOG_FILE="/backup/backup.log"
#
  LOG_FILE=""
#
#
#
#
# 
# ======= DO NOT EDIT BELOW THIS lINE UNLESS YOU KNOW WHAT YOU ARE DOING ========
#
#
#
# 

### Start shell script timer ###
START=$(date +%s)

### Script Variables ###
TMP_BACKUP_DIR="$BACKUP_DIR/tmp"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"
TAR="$(which tar)"
MYSQL_EXCLUDE='information_schema|performance_schema|mysql|test'
NOW=$(date +"%Y-%m-%d")

### Helper function to write to log ###
write_log(){
  echo "$(date +"%c"): bash.sh: $1" >> $LOG_FILE
  echo $1
}

### Prepare directories ###
[ ! -d "$TMP_BACKUP_DIR" ] && mkdir -p "$TMP_BACKUP_DIR"
[ ! -d "$STORAGE_DIR" ] && mkdir -p "$STORAGE_DIR" 
cd $TMP_BACKUP_DIR

### Retrieve MySQL databases ###
echo "Retrieving databases..."
echo
DBS="$($MYSQL -u $MYSQL_USER -p$MYSQL_PASSWD -Bse 'show databases' | egrep -vi $MYSQL_EXCLUDE)"

for DB in $DBS
do
  ### Struct file ###
  FILE=$DB.$NOW.sql.gz

  ### Dump SQL into File and Gzip ###
  echo "Compressing database '$MYSQL_HOST/$DB'..."
  $MYSQLDUMP -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWD $DB | $GZIP -9 > $TMP_BACKUP_DIR/$FILE

  ### Upload to AWS S3 ###
  echo "Uploading '$DB' to 's3://$S3_BUCKET_NAME/$S3_SQL_PATH/$NOW/'..."
  S3="$(s3cmd put $TMP_BACKUP_DIR/$FILE s3://$S3_BUCKET_NAME/$S3_SQL_PATH/$NOW/)"

  ### Report to log ###
  write_log "$S3"
  
  ### Remove local file if KEEP LOCAL is false or move to storage ###
  if $KEEP_LOCAL; then
    [ ! -d "$STORAGE_DIR/$NOW/$S3_SQL_PATH" ] && mkdir -p "$STORAGE_DIR/$NOW/$S3_SQL_PATH"
    mv $TMP_BACKUP_DIR/$FILE $STORAGE_DIR/$NOW/$S3_SQL_PATH
    write_log "Stored backup file '$FILE' to '$STORAGE_DIR/$NOW/$S3_SQL_PATH/'"
  else
    rm $TMP_BACKUP_DIR/$FILE
  fi
  echo
done


### Find directories in WEB ROOT ###
echo "Retrieving web root directories..."
echo
DIRS=$(ls -l $WEB_ROOT | egrep '^d' | awk '{print $9}') ### $9 should be changed to the column the directory name is in when you do ls -l ###

cd $WEB_ROOT

### Loop through Web Root Directories ###
for DIR in $DIRS
do
  ### Struct filename ###
  FILE=$DIR.$NOW.tar.gz

  ### Compress directory ###i
  echo "Compressing webroot '$WEB_ROOT/$DIR'..."
  $TAR -zcf $TMP_BACKUP_DIR/$FILE $DIR
  
  ### Upload to AWS S3 ###
  echo "Uploading '$DIR' to 's3://$S3_BUCKET_NAME/$S3_WEB_PATH/$NOW/'..."
  S3="$(s3cmd put $TMP_BACKUP_DIR/$FILE s3://$S3_BUCKET_NAME/$S3_WEB_PATH/$NOW/)"

  ### Report to log ###
  write_log "$S3"

  ### Remove local file if KEEP LOCAL is false or move to storage ###
  if $KEEP_LOCAL; then
    [ ! -d "$STORAGE_DIR/$NOW/$S3_WEB_PATH" ] && mkdir -p "$STORAGE_DIR/$NOW/$S3_WEB_PATH"
    mv $TMP_BACKUP_DIR/$FILE $STORAGE_DIR/$NOW/$S3_WEB_PATH
    write_log "Stored backup file '$FILE' to '$STORAGE_DIR/$NOW/$S3_WEB_PATH/'"
  else
    rm $TMP_BACKUP_DIR/$FILE
  fi
  echo
done

cd $BACKUP_DIR

### Remove temp directory ###
echo "Cleaning up..."
rm -r $TMP_BACKUP_DIR

### If we're storing files locally, compress that directory and remove backup files older than KEEP_TIME ###
if $KEEP_LOCAL; then
  cd $STORAGE_DIR

  ### Compress directory ##
  FILE="backup-$NOW.tar.gz"
  $TAR -zcf $FILE $NOW
  
  ### Remove $NOW Directory ###
  rm -r $BACKUP_DIR/$NOW
  write_log "Compressed local backups to '$STORAGE_DIR/$FILE'"

  ### Remove local backup storage files older than KEEP_UNTIL ###
  find $STORAGE_DIR -mtime +$KEEP_UNTIL -exec rm -f {} \;
  write_log "Removed backup files older than $KEEP_UNTIL days"
fi

### Stop timer and determine DIFF ###
END=$(date +%s)
DIFF=$(( $END - $START ))

### Log to log file ###
DBS=($DBS)
DIRS=($DIRS)
echo
write_log "------- BACKUP SUMMARY ------"
write_log "Databases found: ${#DBS[@]}"
write_log "Websites found: ${#DIRS[@]}"
write_log "Finished backup in $DIFF seconds"
write_log "-------------------------------------------------------------------------------"

### Exit ###
exit

