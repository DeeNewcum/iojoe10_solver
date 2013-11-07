#!/usr/bin/perl

# tests for:
#   - Move::apply()


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 4;

    use Board;
    use Move;

    use Data::Dumper;


my $board = new Board( width=>3, height=>3 );

$board->cells->[2] = [qw[   5 -11   3 ]];
$board->cells->[1] = [qw[ 500 -11   7 ]];
$board->cells->[0] = [qw[ -11 -11 -11 ]];

select STDERR;
$board->display();
select STDOUT;


ok(ok_move($board, 'c3<',      [8, -11, -11] ));
ok(ok_move($board, 'c3v',      [-11, 10, -11] ));
ok(ok_move($board, 'c2v',      [7, -11, 3] ));
ok(ok_move($board, 'c2<',      [500, 7, -11] ));


sub ok_move {
    my ($board, $move, $row_col) = @_;

    my $b = $board->clone;

    my $m = new Move($move);

    $m->apply($b);

    select STDERR;
    print "========[ $move ]========\n";
    $b->display();
    select STDOUT;

    my $ok = 1;
    if ($move =~ /[<>]$/) {     # $row_col is a row
        my $row = $m->y;
        ## confirm this row is as-specified
        for (my $x=0; $x<$b->width; $x++) {
            if ($b->{cells}[$row][$x] != $row_col->[$x]) {
                $ok = 0;
                last;
            }
        }
        ## confirm that no other rows were modified
        for (my $y=0; $y<$b->height; $y++) {
            next if ($y == $m->y);      # skip the row that was expected to be modified
            for (my $x=0; $x<$b->width; $x++) {
                if ($b->{cells}[$y][$x] != $board->{cells}[$y][$x]) {
                    $ok = 0;
                    last;
                }
            }
        }

    } else {                    # $row_col is a col
        my $col = $m->x;
        ## confirm this column is as-specified
        for (my $y=0; $y<$b->height; $y++) {
            if ($b->{cells}[$y][$col] != $row_col->[$y]) {
                $ok = 0;
                last;
            }
        }
        ## confirm that no other columns were modified
        for (my $y=0; $y<$b->height; $y++) {
            for (my $x=0; $x<$b->width; $x++) {
                next if ($x == $m->x);      # skip the column that was expected to be modified
                if ($b->{cells}[$y][$x] != $board->{cells}[$y][$x]) {
                    $ok = 0;
                    last;
                }
            }
        }
    }

    return $ok;
}

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
