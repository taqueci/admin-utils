#!/bin/sh

# Usage: git-backup.sh [BACKUPDIR] [TARGET] ...

TARGETS=/var/lib/git/repos/*
BACKUPDIR=/var/backups
PREFIX=git-

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
	repos=$backupdir/$PREFIX`basename $t`

	if [ -d $repos ]; then
		echo "Synchronizing Git repository from $t to $repos"
		(cd $repos && git fetch --all -q)
	else
		echo "Cloning Git repository from $t to $repos"
		git clone --mirror -q $t $repos
	fi
done

echo "Completed!"
