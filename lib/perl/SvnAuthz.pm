package SvnAuthz;

use strict;
use warnings;

use PLib;

sub new {
	my $class = shift;
	my $self = {data => {tag => [], block => {}}};

	return bless $self, $class;
}

sub read {
	my ($self, $file) = @_;
	my $fh;

	unless (open $fh, '<', $file) {
		p_error("$file: $!");
		return 0;
	}

	my $name;
	my @tag;
	my %val;

	while (my $line = <$fh>) {
		chomp $line;

		if ($line =~ /^\[([^\]]+)\]/) {
			$name = $1;
			push @tag, $name;
		}
		elsif (defined $name) {
			push @{$val{$name}}, $line;
		}
	}

	close $fh;

	foreach my $t (@tag) {
		$self->append($t, @{$val{$t}});
	}

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
		my $u = $other->{data}->{block}->{$tag};

		$self->append($tag, map {$u->{value}->{$_}} @{$u->{key}});
	}
}

sub content {
	my $self = shift;
	my @content;

	foreach my $tag (@{$self->{data}->{tag}}) {
		my $t = $self->{data}->{block}->{$tag};

		my @blk = ("[$tag]", map {$t->{value}->{$_}} @{$t->{key}});

		push @content, join("\n", @blk);
	}
					 
	return join "\n\n", @content;
}

sub append {
	my ($self, $tag, @val) = @_;

	if (!defined $self->{data}->{block}->{$tag}) {
		push @{$self->{data}->{tag}}, $tag;
		$self->{data}->{block}->{$tag} = {key => [], value => {}};
	}

	my $t = $self->{data}->{block}->{$tag};

	foreach my $v (@val) {
		if ($v =~ /^(~?@?[\w-]+)\s*=/) {
			my $key = $1;

			push @{$t->{key}}, $key if !defined $t->{value}->{$key};
			$t->{value}->{$key} = $v;
		}
	}

	return 1;
}

1;
