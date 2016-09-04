#!/bin/sh

AUTHZ=/var/lib/svn/conf/authz
TMPL=/var/lib/svn/conf/authz.tmpl

CROWD_URL=http://localhost:8095/crowd
CROWD_NAME=fisheye
CROWD_PASSWD=

SCRIPT=`dirname $0`/generate-authz-svn-access-file.py

OWNER=apache
GROUP=apache

tmp_authz=`mktemp`
tmp_config=`mktemp`

cat <<EOF > $tmp_config
crowd.base.url=$CROWD_URL
application.name=$CROWD_NAME
application.password=$CROWD_PASSWD
EOF

if $SCRIPT --config $tmp_config --check-event-token $AUTHZ; then
	: # Do nothing; file is current
else
	$SCRIPT --config $tmp_config $TMPL > $tmp_authz &&
		install -o $OWNER -g $GROUP -m 600 $tmp_authz $AUTHZ || exit 1
fi

rm -f $tmp_authz $tmp_config
