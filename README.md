Website Backup to AWS S3
===========================

A fancy little shell script that backs up your webroot and MySQL databases to Amazon AWS S3.

Databases (except phpmyadmin and 'mysql' databases) will be drumped into a gzipped sql file then uploaded to a specified directory on your Amazon AWS S3 cloud directory. Your gzipped database files will be placed inside a timestamped named directory within your S3_SQL_PATH (if specified).

Your webroot files will go through the same process, compressed and uploaded to a timestamp named directory under your S3_WEB_PATH.

You also have the option of storing your backups on your local server in the specified storage path. If you store them on your local server you can set how many days you want to keep these backups so they don't take up a lot of space.

## Prerequisites

You will need to have `s3cmd` installed on your server. You can find instructions at [Kura.io's](https://kura.io/2012/02/29/backup-a-linux-server-to-amazon-s3-on-debian-6ubuntu-10-04/) website.

I have tested this on an Ubuntu 12.04 machine but I am sure it will work on most servers.

## Installation

To install clone this repo, change the configuration settings in backup.sh and make it executable.

```
git clone git@github.com/adamcole83/backup-to-aws-s3
cd backup-to-aws-s3
chmod +x backup.sh
```

### Configuration options


#### AWS S3 Bucket Name
```
16: S3_BUCKET_NAME="BUCKET-NAME"
```

#### Amazon S3 SQL Directory Path
The path in your S3 bucket to store your mysql backup files. Your files will be placed inside this directory under a date labeled directory. So if you have `S3_SQL_PATH="mysql"` it will put your files in `/bucket/mysql/0000-00-00/`

Leave this blank if you are putting it in your root directory
``` 
23: S3_SQL_PATH="/path/to/directory"
```

#### Amazon S3 Web Files Path
The path in your S3 bucket to store your webroot backup files. Your files will be placed inside this directory under a date labeled directory. So if you have `S3_WEBT_PATH="htdocs"` it will put your files in `/bucket/htdocs/0000-00-00`

Leave this blank if you are putting it in your root directory
```
29: S3_WEB_PATH="/path/to/directory"
```

#### MySQL Database User
```
35: MYSQL_USER="root"
```

#### MySQL Database Password
```
41: MYSQL_PASSWD="sekret"
```

#### MySQL Database Host
```
47: MYSQL_HOST="localhost"
```

#### Webroot directory
Folders (sites) in this directory will get compressed and uploaded to your AWS S3 account
```
56: WEB_ROOT="/var/www"
```

#### Backup Directory
Local directory to work from, if you are not storing your backups locally you can just use the tmp directory or set it to the directory this shell script is in.
```
66: BACKUP_DIR="/backup"
```

#### Keep Local
Would you like to store the files locally?
```
72: KEEP_LOCAL=true
```

#### Local storage directory
You will need the full path to the directory
```
80: STORAGE_DIR="/backup/storage"
```

### Keep Until
How many days do you want to store the local files? This should be in days. Files older than this many days will be deleted.
```
87: KEEP_UNTIL=30
```

#### Log File Path
This needs to be the full path of the log file included or any log file you'd like to write to.
```
96: LOG_FILE="/backup/backup.log"
```

## Running your script via Crontab

You can run your script by setting a cronjob. You can find more details my searching for [creating cron jobs](https://www.google.com/search?q=creating+cron+jobs&oq=creating+cronjo&aqs=chrome.1.69i57j0l5.6154j0j4&sourceid=chrome&espv=210&es_sm=91&ie=UTF-8).

Start a new Crontab

```
sudo crontab -e
```

Set task for every 5 days at 3am
```
0 3 */5 * * /backup/backup.sh
```
