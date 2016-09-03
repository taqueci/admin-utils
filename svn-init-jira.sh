#!/bin/sh

AUTHZ=/var/lib/svn/conf/authz
TMPL=/var/lib/svn/conf/authz.tmpl

dir=`dirname $0`

$dir/svn-init.sh $* || exit 1

perl $dir/svn-authz-tmpl.pl --verbose -t $TMPL -o $TMPL $* || exit 1
