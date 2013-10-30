#!/usr/bin/perl

    use strict;
    use warnings;

    use lib '.';
    use Board;

    use Data::Dumper;

my $b = new Board( width=>6, height=>6 );

# "10 Is Tricky", Level 4

$b->cells->[0] = [qw[ -1 2 10 4 2 9 ]];
$b->cells->[1] = [qw[ 8 5 300 2 4 6 ]];
$b->cells->[2] = [qw[ 10 10 200 1 4 2 ]];
$b->cells->[3] = [qw[ 6 4 5 400 10 10 ]];
$b->cells->[4] = [qw[ 4 1 8 100 6 7 ]];
$b->cells->[5] = [qw[ 3 -2 4 10 5 1 ]];

#print Dumper $b;

#IsUnsolvable::is_unsolvable__noclipping_mark1();

$b->display();

