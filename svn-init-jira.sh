#!/bin/sh

TMPL=/var/lib/svn/conf/authz.tmpl

OWNER=apache
GROUP=apache

dir=`dirname $0`

tmp_tmpl=`mktemp`

$dir/svn-init.sh $* || exit 1

perl $dir/svn-authz-tmpl.pl --verbose -t $TMPL -o $tmp_tmpl $* &&
	install -o $OWNER -g $GROUP -m 600 $tmp_tmpl $TMPL || exit 1

rm -f $tmp_tmpl

$dir/svn-authz-crowd.sh || exit 1
