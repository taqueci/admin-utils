#!/bin/sh

REPOS=/var/lib/git/repos
OWNER=apache
GROUP=apache
PREFIX='#'
URL_REDMINE='https://www.example.com/redmine/issues/%BUGID%'
URL_JIRA='https://www.example.com/jira/browse/%BUGID%'
TMPDIR=/tmp/git-`date +%s`-$$

USER=admin
MAIL="admin@example.com"

if [ -z "$1" ]; then
	echo "*** ERROR ***: Too few arugments..."
	echo "Usage: $0 REPOS_NAME"
	echo "       $0 REPOS_NAME JIRA_PROJ_KEY"
	exit 1
fi

name=$1.git

if [ -z "$2" ]; then
	# Redmine
	prefix=$PREFIX
	bt_url=$URL_REDMINE
	bt_pat=$prefix'\\d+\n\\d+'
else
	# JIRA
	prefix=$2-
	bt_url=$URL_JIRA
	bt_pat=$prefix'\\d+\n'$prefix'\\d+'
fi

if [ -d $REPOS/$name ]; then
	echo "*** ERROR ***: $REPOS/$name: Directory already exists..."
	exit 1
fi

# Creates Git repository
git init --bare --shared $REPOS/$name || exit 1

# Initializes repository
git clone $REPOS/$name $TMPDIR || exit 1

cat <<'EOF' > $TMPDIR/.gitignore
*~
*.bak
*.o
*.obj
EOF

mkdir -p $TMPDIR/_git/hooks || exit 1
hook=$TMPDIR/_git/hooks/commit-msg
cat <<'EOF' | sed "s/@PREFIX@/$prefix/" > $hook
#!/bin/sh

PREFIX="@PREFIX@"

egrep "$PREFIX"'[1-9][0-9]*' "$1" > /dev/null || {
	echo "No issue number" >&2
	exit 1
}

exit 0
EOF
chmod 755 $hook

init=$TMPDIR/_git-config-init.sh
cat <<'EOF' | sed -e "s|@BT_URL@|$bt_url|" -e "s|@BT_PAT@|$bt_pat|" > $init
#!/bin/sh

BT_URL="@BT_URL@"
BT_PAT="@BT_PAT@"

echo "Setting options"
git config bugtraq.url "$BT_URL"
git config bugtraq.logregex "$BT_PAT"

echo "Copying configuration files from _git to .git"
cp -r _git/* .git/

name=`git config user.name`
echo -n "Enter full name (e.g. Steven Tyler) [$name]: "
read name
if [ ! -z "$name" ]; then
	git config --global user.name "$name"
fi

email=`git config user.email`
echo -n "Enter e-mail address [$email]: "
read email
if [ ! -z "$email" ]; then
	git config --global user.email "$email"
fi

echo "Completed!"
EOF
chmod 755 $init

(cd $TMPDIR && \
	git config user.name $USER &&
	git config user.email $MAIL &&
	git config push.default simple && \
	git add .gitignore _git _git-config-init.sh && \
	git commit -m 'Initial commit' && \
	git push) || exit 1
rm -rf $TMPDIR

# Creates hook script for HTTP access
hook=$REPOS/$name/hooks/post-update
cat <<'EOF' > $hook
#!/bin/sh

exec git update-server-info
EOF
chmod 755 $hook

# Changes ownerships
chown -R $OWNER:$GROUP $REPOS/$name || exit 1

echo "Completed!"
