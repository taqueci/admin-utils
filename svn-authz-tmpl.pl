=head1 NAME

svn-authz-tmpl.pl - creates subversion AUTHZ template (for Atlassian Crowd)

=head1 SYSNOPSIS

    svn-authz-tmpl.pl [OPTION] ... REPOS_NAME JIRA_PROJ_KEY [...]

=head1 DESCRIPTION

This script creates a new Booked Scheduler user.

=head1 OPTIONS

=over 4

=item -o FILE, --output=FILE

Write data to FILE.

=item -t FILE, --template=FILE

Read FILE as a template of a AUTHZ template.

=item -a NAME:PATH:LEVEL, --acl=NAME:PATH:LEVEL

Set access level.
e.g. -a %s-users:/trunk:rw

=item -l FILE, --log=FILE

Write log to FILE.

=item --verbose

Print verbosely.

=item --help

Print this help.

=back

=head1 EXAMPLE

When the script is executed as follows:

    perl svn-authz-tmpl.pl -o authz.tmpl \
        -a %s-administrators:/:rw \
        -a %s-developers:/:rw \
        -a %s-users:/:r \
        authz.tmpl jumgle GNR

The script generates AUTHZ template like this:

    [groups]
    GNR-administratos =
    GNR-developers =
    GNR-users =

    [jumgle:/]
    GNR-administratos = rw
    GNR-developers = rw
    GNR-users = r

=head1 AUTHOR

Takeshi Nakamura <taqueci.n@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2016 Takeshi Nakamura. All Rights Reserved.

=cut

use strict;
use warnings;

use Carp;
use Encode qw(encode decode);
use File::Basename;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev gnu_compat);
use Pod::Usage;

my $PROGRAM = basename $0;
my $ENCODING = ($^O eq 'MSWin32') ? 'cp932' : 'utf-8';

my $DEFAULT_ACL = {
	'%s-administrators' => {
		'/' => 'r', '/trunk' => 'rw', '/branches' => 'rw', '/tags' => 'rw'
	},
	'%s-developers' => {
		'/' => 'r', '/trunk' => 'rw', '/branches' => 'rw', '/tags' => 'r'
	},
	'%s-users' => {
		'/' => 'r', '/trunk' => 'r', '/branches' => 'r', '/tags' => 'r'
	},
};

_main(@ARGV) or exit 1;

exit 0;


my $p_message_prefix = "";
my $p_log_file;
my $p_is_verbose = 0;
my $p_encoding = 'utf-8';

sub p_decode {
	return decode($p_encoding, shift);
}

sub p_encode {
	return encode($p_encoding, shift);
}

sub p_message {
	my @msg = ($p_message_prefix, @_);

	print STDERR map {p_encode($_)} @msg, "\n";
	p_log(@msg);
}

sub p_warning {
	my @msg = ("*** WARNING ***: ", $p_message_prefix, @_);

	print STDERR map {p_encode($_)} @msg, "\n";
	p_log(@msg);
}

sub p_error {
	my @msg = ("*** ERROR ***: ", $p_message_prefix, @_);

	print STDERR map {p_encode($_)} @msg, "\n";
	p_log(@msg);
}

sub p_verbose {
	my @msg = @_;

	print STDERR map {p_encode($_)} @msg, "\n" if $p_is_verbose;
	p_log(@msg);
}

sub p_log {
	my @msg = @_;

	return unless defined $p_log_file;

	open my $fh, '>>', $p_log_file or die "$p_log_file: $!\n";
	print $fh map {p_encode($_)} @msg, "\n";
	close $fh;
}

sub p_set_encoding {
	$p_encoding = shift;
}

sub p_set_message_prefix {
	my $prefix = shift;

	defined $prefix or croak 'Invalid argument';

	$p_message_prefix = $prefix;
}

sub p_set_log {
	my $file = shift;

	defined $file or croak 'Invalid argument';

	$p_log_file = $file;
}

sub p_set_verbose {
	$p_is_verbose = (!defined($_[0]) || ($_[0] != 0));
}

sub p_exit {
	my ($val, @msg) = @_;

	print STDERR map {p_encode($_)} @msg, "\n";
	p_log(@msg);

	exit $val;
}

sub p_error_exit {
	my ($val, @msg) = @_;

	p_error(@msg);

	exit $val;
}

sub p_slurp {
	my $file = shift;
	my $fh;

	unless (open $fh, $file) {
		p_error("$file: $!");
		return undef;
	}

	local $/ = undef;

	my $content = <$fh>;

	close $fh;

	return decode $p_encoding, $content;
}

sub _main {
	local @ARGV = @_;

	p_set_message_prefix("$PROGRAM: ");

	my %opt = ('encoding' => $ENCODING, 'output' => '-');
	GetOptions(\%opt, 'output|o=s', 'template|t=s', 'acl|a=s@',
			   'log|l=s', 'verbose', 'help') or exit 1;

	p_set_encoding($opt{encoding});
	p_set_log($opt{log}) if defined $opt{log};
	p_set_verbose(1) if $opt{verbose};

	pod2usage(-exitval => 0, -verbose => 2, -noperldoc => 1) if $opt{help};

	@ARGV > 1 or p_error_exit(1, "Invalid arguments");

	my ($repos, @key) = @ARGV;

	my $acl = $opt{acl} ? _acl($opt{acl}) : $DEFAULT_ACL or return 0;

	my $tmpl = '';
	if (defined $opt{template}) {
		p_verbose("Reading template file $opt{template}");
		$tmpl = p_slurp($opt{template}) or return 0;
	}

	p_verbose("Creating AUTHZ configuration");
	my $authz = _authz($tmpl, $acl, $repos, \@key) or return 0;

	p_verbose("Writing configuration to $opt{output}");
	_write($opt{output}, $authz) or return 0;

	p_verbose("Completed!\n");

	return 1;
}

sub _acl {
	my $arg = shift;
	my %acl;
	my $nerr = 0;

	foreach my $x (@$arg) {
		my ($name, $path, $level) = split /:/, $x;

		if (defined($name) && (length $name > 0) &&
			defined($path) && (length $path > 0)) {
			$acl{$name}{$path} = $level;
		}
		else {
			p_error("$x: Invalid argument");
			$nerr++;
		}
	}

	return ($nerr == 0) ? \%acl :undef;
}

sub _authz {
	my ($tmpl, $acl, $repos, $key) = @_;

	my %c;
	my @path = grep {!$c{$_}++} map {sort keys %{$acl->{$_}}} sort keys %$acl;

	my $authz_groups = _authz_proups($tmpl, $key, sort keys %$acl);
	my $authz_proj = _authz_proj($acl, $repos, \@path, $key);

	my $authz = $tmpl;

	$authz =~ /^\[groups\]/m or $authz .= "\n[groups]\n";

	# Add new groups and access permissions
	$authz =~ s/(\[groups\]\n)/$1$authz_groups/;
	$authz .= "\n$authz_proj";

	return $authz;
}

sub _authz_proups {
	my ($tmpl, $key, @name) = @_;

	# Get groups block
	my ($tmpl_g) = ($tmpl =~ /^\[groups\](.+?)(?:^\[|\z)/sm);

	# Get existing group names
	my @group = defined($tmpl_g) ? ($tmpl_g =~ /^\s*([\w-]+)\s*=/mg) : ();

	my %is_defined;
	$is_defined{$_} = 1 for @group;

	my $txt;

	foreach my $k (@$key) {
		foreach my $n (@name) {
			my $g = sprintf($n, $k);

			$txt .= "$g = \n" unless $is_defined{$g};
		}
	}

	$txt .= "\n";

	return $txt;
}

sub _authz_proj {
	my ($acl, $repos, $path, $key) = @_;
	my @txt;

	foreach my $p (@$path) {
		my $t = "[$repos:$p]\n";

		foreach my $k (@$key) {
			foreach my $r (sort keys %$acl) {
				my $level = $acl->{$r}->{$p};

				$t .= sprintf("\@$r = $level\n", $k) if defined $level;
			}
		}

		push @txt, $t;
	}

	return join "\n", @txt;
}

sub _write {
	my ($file, $content) = @_;
	my $fh;

	unless (open $fh, ">$file") {
		p_error("$file: $!");
		return 0;
	}

	print $fh $content;

	close $fh;

	return 1;
}
