%define name admin-utils
%define version 0.1.0
%define release 1

Summary: Utilities for system administrator
Name: %{name}
Version: %{version}
Release: %{release}
License: GPL2
Group: Applications/System
Source0: %{name}.tar.gz
URL: https://github.com/taqueci/admin-utils
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix: %{_prefix}
BuildArch: noarch
Requires: perl

%description
Miscellaneous scripts for system administrator.

%prep
%setup -q -n admin-utils

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{_sysconfdir}
cp config/admin-utils.conf.sample config/admin-utils.conf
cat <<EOF >> config/admin-utils.conf

# DO NOT EDIT THE FOLLOWING VALUES
ADMIN_UTILS_BIN=%{_bindir}
ADMIN_UTILS_LIB=%{_libexecdir}/admin-utils/lib
ADMIN_UTILS_SCRIPT=%{_libexecdir}/admin-utils/script
EOF
install -m 640 config/admin-utils.conf \
		%{buildroot}%{_sysconfdir}/admin-utils.conf

mkdir -p %{buildroot}%{_sysconfdir}/cron.d
install -m 640 config/admin-utils.cron.sample \
		%{buildroot}%{_sysconfdir}/cron.d/admin-utils

mkdir -p %{buildroot}%{_bindir}
for f in bin/*; do
    install -m 755 $f %{buildroot}%{_bindir}/
done

mkdir -p %{buildroot}%{_libexecdir}/admin-utils
for d in lib script; do
    cp -r $d %{buildroot}%{_libexecdir}/admin-utils/
done

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%config(noreplace) %{_sysconfdir}/admin-utils.conf
%config(noreplace) %{_sysconfdir}/cron.d/admin-utils
%{_bindir}/admin-bitbucket-prep
%{_bindir}/admin-git-backup
%{_bindir}/admin-git-init
%{_bindir}/admin-svn-authz-crowd
%{_bindir}/admin-svn-authz-update
%{_bindir}/admin-svn-backup
%{_bindir}/admin-svn-init
%{_bindir}/admin-mysql-backup
%{_bindir}/admin-psql-backup
%{_libexecdir}/admin-utils
