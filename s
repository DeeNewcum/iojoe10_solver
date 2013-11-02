#!/usr/bin/perl

    use strict;
    use warnings;

    use lib '.';
    use Board;
    use Move;

    use Data::Dumper;


my $b;

# level Blocks / 16
if (1) {
    $b = new Board( width=>4, height=>4 );

    $b->cells->[3] = [qw[ 5 6 4 2 ]];
    $b->cells->[2] = [qw[ 1 3 4 3 ]];
    $b->cells->[1] = [qw[ 10 10 7 10 ]];
    $b->cells->[0] = [qw[ 4 2 5 4 ]];
}

# level Tricky / 4
if (0) {
    $b = new Board( width=>6, height=>6 );

    $b->cells->[5] = [qw[ -1 2 10 4 2 9 ]];
    $b->cells->[4] = [qw[ 8 5 300 2 -11 10 ]];
    $b->cells->[3] = [qw[ 10 10 200 1 4 2 ]];
    $b->cells->[2] = [qw[ 6 4 5 400 10 10 ]];
    $b->cells->[1] = [qw[ 4 1 8 100 6 7 ]];
    $b->cells->[0] = [qw[ 3 -2 4 10 5 1 ]];
}

#die Dumper $b;

my $c = $b->clone;
#print Dumper $c; exit;
$c->display();

#IsUnsolvable::is_unsolvable__noclipping_mark1();

#$b->display();

foreach my $move (
        qw[  c4<
             b3> c3>
             c2^ a3> c3^ d4<
             c1^ c3< a3^
             d1< b1<
]) {
    $move = parse_move($move);
}
