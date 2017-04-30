=head1 NAME

svn-authz-tmpl.pl - creates subversion AUTHZ template file

=head1 SYSNOPSIS

    svn-authz-tmpl.pl [OPTION] ... USER:PATH1=PERM1[,PATH2=PARM2...] ...

=head1 DESCRIPTION

This script creates authz file for subversion.

=head1 OPTIONS

=over 4

=item -o FILE, --output=FILE

Write data to FILE.

=item -r NAME, --repository=NAME

Creates configuration for a repository NAME.

=item -l FILE, --log=FILE

Write log to FILE.

=item --verbose

Print verbosely.

=item --help

Print this help.

=back

=head1 EXAMPLE

When the script is executed as follows:

	perl svn-authz-tmpl -o /var/lib/svn/conf/authz \
		-r jungle -r nightrain \
		@GNR-administrators:/=r,/trunk=rw,/branches=rw,/tags=rw \
		@GNR-developers:/=r,/trunk=rw,/branches=rw,/tags=r \
		@GNR-users:/=r,/trunk=r,/branches=r,/tags=r

The script generates AUTHZ file like this:

    [groups]
    GNR-administrators =
    GNR-developers =
    GNR-users =

    [jungle:/]
    @GNR-administrators = r
    @GNR-developers = r
    @GNR-users = r

    [jungle:/trunk]
    @GNR-administrators = rw
    @GNR-developers = rw
    @GNR-users = r

    [jungle:/branches]
    @GNR-administrators = rw
    @GNR-developers = rw
    @GNR-users = r

    [jungle:/tags]
    @GNR-administrators = rw
    @GNR-developers = r
    @GNR-users = r

    [nightrain:/]
    @GNR-administrators = r
    @GNR-developers = r
    @GNR-users = r

    ...

=head1 AUTHOR

Takeshi Nakamura <taqueci.n@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2017 Takeshi Nakamura. All Rights Reserved.

=cut

use strict;
use warnings;

use utf8;

use File::Basename;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev gnu_compat);
use Pod::Usage;

use PLib;
use SvnAuthz;

my $PROGRAM = basename $0;

_main(@ARGV) or exit 1;

exit 0;


sub _main {
	local @ARGV = @_;

	p_set_message_prefix("$PROGRAM: ");

	my %opt = ('output' => '-');
	GetOptions(\%opt, 'output|o=s', 'repository|r=s@',
			   'log|l=s', 'verbose', 'help') or return 0;

	p_set_log($opt{log}) if defined $opt{log};
	p_set_verbose(1) if $opt{verbose};

	pod2usage(-exitval => 0, -verbose => 2, -noperldoc => 1) if $opt{help};

	@ARGV > 0 or p_error_exit(1, "Too few arguments");

	my @arg = @ARGV;

	my $authz = SvnAuthz->new();

	my $data = _data($opt{repository}, @arg) or return 0;

	p_verbose("Creating AUTHZ configuration");
	foreach my $d (@$data) {
		$authz->append($d->{tag}, @{$d->{value}});
	}

	p_verbose("Writing configuration to $opt{output}");
	$authz->write($opt{output}) or return 0;

	p_verbose("Completed!\n");

	return 1;
}

sub _data {
	my ($name, @arg) = @_;
	my @gr;
	my %blk;

	foreach my $ar (@arg) {
		my ($key, @val) = split /[:,]/, $ar;

		push @gr, "$1 =" if $key =~ /^@(.+)$/;

		foreach my $v (@val) {
			my ($path, $perm) = split /=/, $v;
			push @{$blk{"$path"}}, "$key = $perm";
		}
	}

	my @data = @gr ? ({tag => 'groups', value => \@gr}) : ();

	my @n = $name ? map {"$_:"} @$name : ('');

	foreach my $p (@n) {
		push @data, map {{tag => "$p$_", value => $blk{$_}}} sort keys %blk;
	}

	return \@data;
}
