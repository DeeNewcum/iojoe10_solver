#!/usr/bin/perl

# tests for:
#   - Move::apply()


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 3;

    use Board;
    use Move;

    use Data::Dumper;


my $board = new Board( width=>3, height=>3 );

$board->cells->[2] = [qw[   5 -11   3 ]];
$board->cells->[1] = [qw[  10 -11   7 ]];
$board->cells->[0] = [qw[ -11 -11 -11 ]];


select STDERR;
$board->display();
select STDOUT;



showmove($board, 'c3<');
showmove($board, 'c3v');
showmove($board, 'c2v');
showmove($board, 'c2<');

sub showmove {
    my ($board, $move) = @_;

    my $b = $board->clone;

    my $m = new Move($move);

    $m->apply($b);

    select STDERR;
    print "========[ $move ]========\n";
    $b->display();
    select STDOUT;
}
