#!/usr/bin/perl

# very basic Move.pm tests
#
# tests for:
#   - Move::new()
#   - Move::toString()


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 3;
    use Move;

    use Data::Dumper;

my $m = new Move('d3v');

ok( $m->x == 3   &&  $m->y == 2 );

ok( $m->dir == 3 );

ok( $m->toString() eq 'd3v' );
