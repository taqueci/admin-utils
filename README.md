# misc

## git-init.sh

Creates Git repository with initializaion script.

### Usage

Set variables in the script and execute.

For Redmine:

    # ./git-init.sh REPOS_NAME

For JIRA:

    # ./git-init.sh REPOS_NAME JIRA_PROJ_KEY

## svn-init.sh

Creates Subversion repository with standard layout and a hook script.

### Usage

Set variables in the script and execute.

For Redmine:

    # ./svn-init.sh REPOS_NAME

For JIRA:

    # ./svn-init.sh REPOS_NAME JIRA_PROJ_KEY

## diskck.sh

Checks disk usage.

### Usage

Set `LIMIT` and `TARGETS` in the script and put into `/etc/cron.daily`.
