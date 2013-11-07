#!/usr/bin/perl

# tests for:
#   - Move::new()
#   - Move::toString()


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 3;

    use TreeTraversal;
    use Board;
    use Move;

    use Data::Dumper;

my $board = new Board( width => 2, height => 2);


$board->cells->[1] = [qw[   7 -11 ]];
$board->cells->[0] = [qw[ -11   3 ]];


my $solution = TreeTraversal::IDDFS($board);

#print Dumper $solution;


