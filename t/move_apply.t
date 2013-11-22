#!/usr/bin/perl

# tests for:
#   - Move::apply()


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 15;

    use Board;
    use Move;

    use Data::Dumper;


my $board = new Board( width=>3, height=>3 );

$board->cells->[2] = [qw[   5 -11   3 ]];
$board->cells->[1] = [qw[ 500 -11   7 ]];
$board->cells->[0] = [qw[ -11 -11 -11 ]];

    #select STDERR;
    $board->display()   if -t STDOUT;
    #select STDOUT;

ok(ok_move($board, 'c3<',      [  8, -11, -11] ));
ok(ok_move($board, 'c3v',      [-11,  10, -11] ));
ok(ok_move($board, 'c2v',      [  7, -11,   3] ));
ok(ok_move($board, 'c2<',      [500,   7, -11] ));
ok(ok_move($board, 'a2>',      [-11, 500,   7] ));
ok(ok_move($board, 'a2v',      undef ));




#####################################################
################### sliders #########################
#####################################################

$board = Board::new_from_string(<<'EOF');
       .   .   .   .
     100 600   .   .
       .   . 700   .
       .   .   .   .
EOF

    #select STDERR;
    $board->display()   if -t STDOUT;
    #select STDOUT;

ok(ok_move($board, 'a3^',      [ -11, -11, -11, 100 ] ));
ok(ok_move($board, 'a3v',      undef ));

ok(ok_move($board, 'b3^',      [ -11, -11, -11, 600 ] ));
ok(ok_move($board, 'b3v',      [ 600, -11, -11, -11 ] ));
ok(ok_move($board, 'b3>',      undef ));

ok(ok_move($board, 'c2>',      [ -11, -11, -11, 700 ] ));
ok(ok_move($board, 'c2<',      [ 700, -11, -11, -11 ] ));
ok(ok_move($board, 'c2^',      [ -11, -11, -11, 700 ] ));



#####################################################
############# invert and multiply ###################
#####################################################


$board = Board::new_from_string(<<'EOF');
     800   .   2
       7   .   .
       .   .   .
EOF

ok(ok_move($board, 'c3<',      [ -2, -11, -11 ] ));



# parameters:
#   $row_col    The expected state of the specific column or row where movement took place.
#               'Undef' means that Move::apply() was expected to return 0
#                       (and that the board was expected to remain unchanged)
sub ok_move {
    my ($board, $move, $row_col) = @_;

    my $b = $board->clone;

    my $m = new Move($move);

    my $apply_ret = $m->apply($b);

    if (defined($row_col) != !!$apply_ret) {
        return 0;
    }

    #select STDERR;
    if (-t STDOUT) {
        print "========[ $move ]========\n";
        $b->display();
    }
    #select STDOUT;

    my $ok = 1;
    if (defined($row_col)) {

        ## $row_col is a row
        if ($move =~ /[<>]$/) {     
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

        } else {                    
        ## $row_col is a col
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

    } else {
    ## we expected the board to not change at all

        for (my $y=0; $y<$b->height; $y++) {
            for (my $x=0; $x<$b->width; $x++) {
                if ($b->{cells}[$y][$x] != $board->{cells}[$y][$x]) {
                    $ok = 0;
                    last;
                }
            }
        }

    }


    return $ok;
}
