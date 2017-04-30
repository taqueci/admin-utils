package SvnAuthz;

use strict;
use warnings;

use PLib;

sub new {
	my $class = shift;
	my $self = {};

	return bless $self, $class;
}

sub read {
	my ($self, $file) = @_;
	my $fh;

	unless (open $fh, '<', $file) {
		p_error("$file: $!");
		return 0;
	}

	my $tag;
	my %data = (tag => [], block => {});

	while (my $line = <$fh>) {
		chomp $line;

		if ($line =~ /^\[([^\]]+)\]/) {
			$tag = $1;

			push @{$data{tag}}, $tag;
		}
		elsif ($line =~ /^(~?@?[\w-]+)\s*=/) {
			my $key = $1;

			push @{$data{block}{$tag}{key}}, $key;
			$data{block}{$tag}{value}{$key} = $line;
		}
	}

	close $fh;

	$self->{data} = \%data;

	return 1;
}

sub write {
	my ($self, $file) = @_;
	my $fh;

	unless (open $fh, ">$file") {
		p_error("$file: $!");
		return 0;
	}

	print $fh $self->content(), "\n";

	close $fh;

	return 1;
}

sub merge {
	my ($self, $other) = @_;

	foreach my $tag (@{$other->{data}->{tag}}) {
		my $t = $other->{data}->{block}->{$tag};

		if (!defined $self->{data}->{block}->{$tag}) {
			push @{$self->{data}->{tag}}, $tag;
			$self->{data}->{block}->{$tag} = {};
		}

		foreach my $key (@{$t->{key}}) {
			my $b = $self->{data}->{block}->{$tag};

			push @{$b->{key}}, $key if !defined $b->{value}->{$key};
			$b->{value}->{$key} = $t->{value}->{$key};
		}
	}
}

sub content {
	my $self = shift;
	my @content;

	foreach my $tag (@{$self->{data}->{tag}}) {
		my @blk = ("[$tag]");
		my $t = $self->{data}->{block}->{$tag};

		foreach my $key (@{$t->{key}}) {
			push @blk, $t->{value}->{$key};
		}

		push @content, join("\n", @blk);
	}
					 
	return join "\n\n", @content;
}

sub append {
	my ($self, $tag, @val) = @_;

	if (!defined $self->{data}->{block}->{$tag}) {
		push @{$self->{data}->{tag}}, $tag;
		$self->{data}->{block}->{$tag} = {};
	}

	foreach my $v (@val) {
		if ($v =~ /^(~?@?[\w-]+)\s*=/) {
			my $key = $1;

			if (!defined $self->{data}->{block}->{$tag}->{value}->{$key}) {
				push @{$self->{data}->{block}->{$tag}->{key}}, $key;
			}

			$self->{data}->{block}->{$tag}->{value}->{$key} = $v;
		}
	}

	return 1;
}

1;
