#!/bin/sh

LIMIT=90
TARGETS="/var /tmp"

for t in $TARGETS; do
	usage=`df $t | tail -1 | sed 's/^.* \([0-9]*\)%.*$/\1/'`
	if [ $usage -gt $LIMIT ]; then
		echo "*** WARNING ***: $t: Not enough disk space ($usage%)" >&2
	fi
done
