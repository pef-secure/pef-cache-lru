package PEF::CacheLRU;
use strict;
use warnings;
use constant {
	NEXT    => 0,
	PREV    => 1,
	KEY     => 2,
	VALUE   => 3,
	HEAD    => 0,
	TAIL    => 1,
	NODES   => 2,
	SIZE    => 3,
	MAXSIZE => 4,
};

our $VERSION = "0.01";

sub new {
	my ($class, $max_size) = @_;
	my $self = bless [[undef, undef], undef, {}, 0, $max_size,], $class;
	$self->[TAIL] = $self->[HEAD];
	$self;
}

sub max_size {
	$_[0]->[MAXSIZE];
}

sub size {
	$_[0]->[SIZE];
}

sub _promote {
	my ($self, $node) = @_;
	my $pre = $node->[PREV];
	$node->[PREV]             = undef;
	$pre->[NEXT]              = $node->[NEXT];
	$pre->[NEXT][PREV]        = $pre;
	$node->[NEXT]             = $self->[HEAD];
	$self->[HEAD]             = $node;
	$self->[HEAD][NEXT][PREV] = $self->[HEAD];
}

sub remove {
	my ($self, $key) = @_;
	return if not exists $self->[NODES]{$key};
	my $node = $self->[NODES]{$key};
	--$self->[SIZE];
	if ($node == $self->[HEAD]) {
		$self->[HEAD] = $node->[NEXT];
		$self->[HEAD][PREV] = undef;
	} else {
		my $pre = $node->[PREV];
		$pre->[NEXT] = $node->[NEXT];
		$node->[NEXT][PREV] = $pre;
	}
	delete $self->[NODES]{$node->[KEY]};
	$node->[NEXT] = undef;
	$node->[PREV] = undef;
	$node->[VALUE];
}

sub set {
	my ($self, $key, $value) = @_;
	if (my $node = $self->[NODES]{$key}) {
		$node->[VALUE] = $value;
		$self->_promote($node) if $node != $self->[HEAD];
	} else {
		$self->[HEAD] = [$self->[HEAD], undef, $key, $value];
		$self->[HEAD][NEXT][PREV] = $self->[HEAD];
		$self->[NODES]{$key} = $self->[HEAD];
		if (++$self->[SIZE] > $self->[MAXSIZE]) {
			my $pre_least = $self->[TAIL][PREV];
			if (my $pre = $pre_least->[PREV]) {
				delete $self->[NODES]{$pre_least->[KEY]};
				$pre->[NEXT]        = $self->[TAIL];
				$self->[TAIL][PREV] = $pre;
				$pre_least->[NEXT]  = undef;
				$pre_least->[PREV]  = undef;
				--$self->[SIZE];
			}
		}
	}
	$value;
}

sub get {
	my ($self, $key) = @_;
	if (my $node = $self->[NODES]{$key}) {
		$self->_promote($node) if $node != $self->[HEAD];
		$node->[VALUE];
	} else {
		return;
	}
}

1;

__END__
 
=head1 NAME
 
PEF::CacheLRU - a simple, fast implementation of LRU cache in pure perl
 
=head1 SYNOPSIS
 
    use PEF::CacheLRU;
 
    my $cache = PEF::CacheLRU->new($max_num_of_entries);
 
    $cache->set($key => $value);
 
    $value = $cache->get($key);
 
    $removed_value = $cache->remove($key);
 
=head1 DESCRIPTION
 
PEF::CacheLRU is a simple, fast implementation of an in-memory LRU cache in pure perl. It is inspired by L<Cache::LRU> but works faster.
 
=head1 METHODS
 
=head2 PEF::CacheLRU->new($max_num_of_entries)
 
Creates a new cache object.  The only parameter is the maximum number of entries to be stored within the cache object.
 
=head2 $cache->get($key)
 
Returns the cached object if exists, or undef otherwise.
 
=head2 $cache->set($key => $value)
 
Stores the given key-value pair.
 
=head2 $cache->remove($key)
 
Removes data associated to the given key and returns the old value, if any.
 
=head2 $cache->size
 
Returns used cache size.
 
=head2 $cache->max_size
 
Returns cache capacity.
 
=head1 Authors

This module was written and is maintained by:

=over

=item * PEF Developer <pef-secure@yandex.ru>

=back

=head1 Speed

What is the difference between L<Cache::LRU> and this module?

Using slightly modified benchmark from L<Cache::LRU> I get:

  cache_hit:
                  Rate    Cache::LRU PEF::CacheLRU
  Cache::LRU     872/s            --          -52%
  PEF::CacheLRU 1815/s          108%            --
  
  cache_set:
                  Rate    Cache::LRU PEF::CacheLRU
  Cache::LRU    5.81/s            --          -22%
  PEF::CacheLRU 7.44/s           28%            --
  
  cache_set_hit:
                 Rate    Cache::LRU PEF::CacheLRU
  Cache::LRU    155/s            --          -35%
  PEF::CacheLRU 238/s           54%            --

=head1 SEE ALSO
 
L<Cache::LRU>
 
=head1 LICENSE
 
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
See <http://www.perlfoundation.org/artistic_license_2_0>
 
=cut
