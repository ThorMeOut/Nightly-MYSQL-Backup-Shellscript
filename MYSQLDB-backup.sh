#!/bin/sh
## MySQL backup script
##
## Uses a grep on "SHOW DATABASES" function in MSYSQLDUMP to find all databases to back up.
## Backup individual SQL DB's and their associated table structure into single DB files,
## rather than one big file as with --all-databases. Then compress the resulting file to
## save space . This will make single restores faster and easier.


### MYSQL Setup ###
USER="dbusername"
PASSWORD="dbpassword"

### Backup Destination ###
OUTPUTDIR="/DB/directory/backupdestination" # EG: /Volumes/backup_vol/prod

### Binaries ###
#MYSQLDUMP=$(which mysqldump)
#MYSQL=$(which mysql) 
#GZIP=$(which gzip)
MYSQL=/usr/local/mysql/bin/mysql
GZIP=/usr/bin/gzip
MYSQLDUMP=/usr/local/mysql/bin/mysqldump

### Datestamp the backup - Today + hour in 24h format ###
NOW=$(date +"%d-%m-%y")
### Create timestamp directory in backup destination ###
mkdir $OUTPUTDIR/$NOW
### Set directory permissions at backup location (optional)###
chown -R admin $OUTPUTDIR/$NOW
chgrp -R admin $OUTPUTDIR/$NOW


### Loop through the MSQL schema for DB names, used to structure output file ###
### --single-transaction - for InnoDB tables
if [ -z "$1" ]; then
	databases=`$MYSQL --user=$USER --password=$PASSWORD --batch --skip-column-names -e "SHOW DATABASES;" | grep -v 'mysql\|information_schema'`
	for database in $databases; do
		$MYSQLDUMP \
		--user=$USER --password=$PASSWORD \
		--force \
		--quote-names --dump-date \
		--opt --single-transaction \
		--events --routines --triggers \
		--databases $database \
		--log-error="$OUTPUTDIR/$NOW/$database.log" \
		--result-file="$OUTPUTDIR/$NOW/$database.sql"
		$GZIP -9 $OUTPUTDIR/$NOW/$database.sql # -9 Max compression
	done
else
	for database in ${@}; do
		$MYSQLDUMP \
		--user=$USER --password=$PASSWORD \
		--force \
		--quote-names --dump-date \
		--opt --single-transaction \ #INNO DB friendly
		--events --routines --triggers \
		--databases $database \
		--log-error="$OUTPUTDIR/$NOW/$database.log" \
		--result-file="$OUTPUTDIR/$NOW/$database.sql"
		$GZIP -9 $OUTPUTDIR/$NOW/$database.sql # -9 Max compression
	done
fi

### OCD Cleanup - Remove Zero byte log files ###
find $OUTPUTDIR/$NOW/ -type f -size 0 -exec rm {} \;