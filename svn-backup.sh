#!/bin/sh

# Usage: svn-backup.sh [BACKUPDIR] [TARGET] ...

TARGETS=/var/lib/svn/repos/*
BACKUPDIR=/var/backups
PREFIX=svn-

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
	file=$backupdir/$PREFIX`basename $t`.gz
	rev=`svnlook youngest $t`

	echo "Creating Subversion dump from $t@r$rev to $file"
	svnadmin dump -q $t | gzip -c > $file
done

echo "Completed!"
