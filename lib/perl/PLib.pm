package PLib;

use strict;
use warnings;

use Carp;
use Encode;

use base 'Exporter';

our @EXPORT = qw(
	p_message p_warning p_error p_log p_verbose
	p_set_message_prefix p_set_log p_set_encoding p_set_verbose
	p_error_exit p_slurp
);

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

1;
