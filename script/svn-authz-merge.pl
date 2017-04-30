=head1 NAME

svn-authz-merge.pl - merges subversion AUTHZ files

=head1 SYSNOPSIS

    svn-authz-merge.pl [OPTION] ... AUTHZ1 AUTHZ2 ...

=head1 DESCRIPTION

This script merges authz files.

=head1 OPTIONS

=over 4

=item -o FILE, --output=FILE

Write data to FILE.

=item -l FILE, --log=FILE

Write log to FILE.

=item --verbose

Print verbosely.

=item --help

Print this help.

=back

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
	GetOptions(\%opt, 'output|o=s', 'log|l=s', 'verbose', 'help') or return 0;

	p_set_log($opt{log}) if defined $opt{log};
	p_set_verbose(1) if $opt{verbose};

	pod2usage(-exitval => 0, -verbose => 2, -noperldoc => 1) if $opt{help};

	@ARGV > 0 or p_error_exit(1, "Too few arguments");

	my @file = @ARGV;
	my $nerr = 0;

	my $authz = SvnAuthz->new();

	foreach my $f (@file) {
		my $other = SvnAuthz->new();

		p_verbose("Reading AUTHZ file $f");
		unless ($other->read($f)) {
			$nerr++;
			next;
		}

		p_verbose("Merging AUTHZ file $f");
		$authz->merge($other);
	}

	return 0 if $nerr > 0;

	p_verbose("Writing configuration to $opt{output}");
	$authz->write($opt{output}) or return 0;

	p_verbose("Completed!\n");

	return 1;
}
