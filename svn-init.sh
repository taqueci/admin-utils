#!/bin/sh

REPOS=/var/lib/svn/repos
OWNER=apache
GROUP=apache
PREFIX='#'
URL_REDMINE='/redmine/issues/%BUGID%'
URL_JIRA='/jira/browse/%BUGID%'
TMPDIR=/tmp/svn-`date +%s`-$$

USER=admin

if [ -z "$1" ]; then
	echo "*** ERROR ***: Too few arugments..."
	echo "Usage: $0 REPOS_NAME"
	echo "       $0 REPOS_NAME JIRA_PROJ_KEY [...]"
	exit 1
fi

name=$1

shift

if [ -z "$1" ]; then
	# Redmine
	prefix=$PREFIX
	bt_url=$URL_REDMINE
	bt_pat=$prefix'\d+'"
"'\d+'
else
	# JIRA
	prefix='('$1

	shift

	while [ "$1" != "" ]; do
		prefix=$prefix'|'$1
		shift
	done

	prefix=$prefix')'-

	bt_url=$URL_JIRA
	bt_pat=$prefix'\d+'"
"$prefix'\d+'
fi

if [ -d $REPOS/$name ]; then
	echo "*** ERROR ***: $REPOS/$name: Directory already exists..."
	exit 1
fi

# Creates Subversion repository
svnadmin create $REPOS/$name || exit 1

# Initializes repository
svn co file:///$REPOS/$name $TMPDIR || exit 1
svn mkdir $TMPDIR/trunk $TMPDIR/branches $TMPDIR/tags || exit 1
svn propset bugtraq:url $bt_url $TMPDIR/trunk || exit 1
svn propset bugtraq:logregex "$bt_pat" $TMPDIR/trunk || exit 1
svn commit --username=$USER -m '' $TMPDIR || exit 1
rm -rf $TMPDIR

# Creates hook script
hook=$REPOS/$name/hooks/pre-commit
cat <<'EOF' | sed "s/@PREFIX@/$prefix/" > $hook
#!/bin/sh

REPOS="$1"
TXN="$2"
PREFIX="@PREFIX@"

SVNLOOK=/usr/bin/svnlook
$SVNLOOK log -t "$TXN" "$REPOS" | egrep "$PREFIX"'[1-9][0-9]*' > /dev/null

if [ "$?" != "0" ]; then
	echo "No issue number" >&2
	exit 1
fi

exit 0
EOF

chmod 755 $hook

# Changes ownerships
chown -R $OWNER:$GROUP $REPOS/$name || exit 1

echo "Completed!"
