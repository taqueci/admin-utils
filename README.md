# admin-utils

Miscellaneous scripts

## Usage

Copy `config/admin-utils.conf.sample` to `config/admin-utils.conf`
and set suitable variables in `config/admin-utils.conf`.

## bin/admin-git-init

Creates Git repository with initializaion script.

### Usage

For Redmine:

    ./bin/admin-git-init REPOS_NAME

For JIRA:

    ./bin/admin-git-init REPOS_NAME JIRA_PROJ_KEY

## bin/admin-svn-init

Creates Subversion repository with standard layout and a hook script.

### Usage

For Redmine:

    ./bin/admin-svn-init REPOS_NAME

For JIRA:

    ./bin/admin-svn-init REPOS_NAME JIRA_PROJ_KEY

## bin/admin-svn-authz-update

Creates Subversion AUTHZ template file for Atlassian Crowd
and update AUTHZ file.

### Usage

    ./bin/admin-svn-authz-update JIRA_PROJ_KEY \
        -r repos1 -r repos2 \
        @xyz-administrators:/=r,/trunk=rw,/branches=rw,/tags=rw \
        @xyz-developers:/=r,/trunk=rw,/branches=rw,/tags=r \
        @xyz-users:/=r,/trunk=r,/branches=r,/tags=r
