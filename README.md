# admin-utils

Miscellaneous scripts

## Usage

Copy `config/admin.cfg.tmpl` to `config/admin.cfg`
and set suitable variables in `config/admin.cfg`.

## bin/git-init

Creates Git repository with initializaion script.

### Usage

For Redmine:

    ./bin/git-init REPOS_NAME

For JIRA:

    ./bin/git-init REPOS_NAME JIRA_PROJ_KEY

## bin/svn-init

Creates Subversion repository with standard layout and a hook script.

### Usage

For Redmine:

    ./bin/svn-init REPOS_NAME

For JIRA:

    ./bin/svn-init REPOS_NAME JIRA_PROJ_KEY

## bin/svn-authz-update

Creates Subversion AUTHZ template file for Atlassian Crowd
and update AUTHZ file.

### Usage

    ./bin/svn-authz-update JIRA_PROJ_KEY \
        -r repos1 -r repos2 \
        @xyz-administrators:/=r,/trunk=rw,/branches=rw,/tags=rw \
        @xyz-developers:/=r,/trunk=rw,/branches=rw,/tags=r \
        @xyz-users:/=r,/trunk=r,/branches=r,/tags=r
