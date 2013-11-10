package TreeTraversal;

    use strict;
    use warnings;

    use Board;
    use Move;
    use IsUnsolvable;

    use Time::HiRes qw( time );
    use Data::Dumper;

our $num_moves = 0;      # the number of times that Move::apply() has been called
my $display_every_n = 0;


sub list_available_moves {
    my ($board) = shift;

    my @moves;

    for (my $y=0; $y<$board->height; $y++) {
        for (my $x=0; $x<$board->width; $x++) {
            my $cell = $board->{cells}[$y][$x];
            next if ($cell == -11 || $cell == 10);

            foreach my $dir (1..4) {
                push @moves, new Move(x => $x, y => $y, dir => $dir);
            }
        }
    }
    return \@moves;
}


# iterative deepening depth-first search
sub IDDFS {
    my ($board) = @_;

    for (my $depth=1;  ; $depth++) {
        print "==== trying to depth $depth ====\n";
        my $started = time();
        $num_moves = 0;

        my %seen;
        my $ret = _IDDFS($board, $depth, \%seen);
        return $ret if defined($ret);

        my $duration = time() - $started;
        printf "%-15s  %40s\n",
            sprintf("%6.2f sec", $duration),
            sprintf("%s moves", commify($num_moves));
        #printf "%6.2f seconds\n", commify($num_moves), $duration;
    }

    return undef;
}


# Returns a list-ref of moves, if a solution was found.
sub _IDDFS {
    my ($board, $depth_remaining, $seen) = @_;

    my @moves = @{ list_available_moves($board) };

    foreach my $move (@moves) {
        my $new_board = $board->clone;
        $num_moves++;
        $move->apply($new_board)
            or next;
        if ($new_board->has_won) {
            return [$move];
        }

        next if ($depth_remaining <= 0);
        next if $seen->{ $new_board->hash }++;
        next if IsUnsolvable::noclipping_mark1($new_board);

        $display_every_n++;
        if ($display_every_n % 1000 == 0) {
            $new_board->display;        # display the board every 1,000 moves
        }

        my $ret = _IDDFS( $new_board, $depth_remaining - 1, $seen);
        if (defined($ret)) {
            unshift @$ret, $move;
            return $ret;
        }
    }

    return undef;
}

sub move_list_toString {
    my ($moves) = shift;

    my $str = '';
    foreach my $move (@$moves) {
        $str .= $move->toString . "  ";
    }
    return $str;
}


sub display_solution {
    my ($moves, $board) = @_;

    $board = $board->clone;     # don't corrupt the one that was passed to us

    $board->display;

    foreach my $move (@$moves) {
        $move->apply($board);
        print "  " x ($board->width + 3), $move->toString, "\n";
        $board->display;
        print "\n";
    }
}



# add commas to a number
sub commify {(my$text=reverse$_[0])=~s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;scalar reverse$text}


1;
