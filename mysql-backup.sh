#!/bin/sh

# Usage: mysql-backup.sh [BACKUPDIR] [TARGET] ...

TARGETS="redmine"
BACKUPDIR=/var/backups
PREFIX=mysql-

week=`date +%w`

if [ $week = "0" ]; then
	subdir=weekly/w`date +%02W`
else
	subdir=daily/d`date +%02d`
fi

if [ -z "$1" ]; then
	backupdir=$BACKUPDIR/$subdir
else
	backupdir=$1/$subdir
fi

if [ -z "$2" ]; then
	targets=$TARGETS
else
	shift
	targets=$@
fi

test -d $backupdir || mkdir -p $backupdir || exit 1

for t in $targets; do
	file=$backupdir/$PREFIX$t.gz

	echo "Creating MySQL dump from $t to $file"
	mysqldump -uroot -pxxxxxxxx $t | gzip -c > $file
done

echo "Completed!"
