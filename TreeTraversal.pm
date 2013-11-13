package TreeTraversal;

    use strict;
    use warnings;

    use Board;
    use Move;
    use IsUnsolvable;

    use Time::HiRes qw( time );
    use Data::Dumper;

my $num_moves = 0;      # the number of times that Move::apply() has been called
my $num_boards = 0;     # the number of unique board configurations we've evaluated so far
my $started;
my $display_every_n = 0;


sub list_available_moves {
    my ($board) = shift;

    my @moves;

    for (my $y=0; $y<$board->height; $y++) {
        for (my $x=0; $x<$board->width; $x++) {
            my $cell = $board->{cells}[$y][$x];
            next unless (Move::_is_piece_movable($cell));

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

    $num_moves = 0;
    $started = time();

    for (my $depth=1;  ; $depth++) {
        print "==== trying to depth $depth ====\n";

        my %seen;
        my $ret = _IDDFS($board, $depth, \%seen);
        return $ret if defined($ret);

        print_stats();

        #die "quitting after first round\n";
    }

    return undef;
}

# show the stats so far
sub print_stats {
    my $elapsed = time() - $started;
    printf "         %12s moves,   %8s boards,   %.2f seconds,   %d microseconds per move\n",
                commify($num_moves),
                commify($num_boards),
                $elapsed,
                1000000 * $elapsed / $num_moves;
}


# Returns a list-ref of moves, if a solution was found.
sub _IDDFS {
    my ($board, $depth_remaining, $seen) = @_;

    my @moves = @{ list_available_moves($board) };
    #die move_list_toString(\@moves) . "\n";

    #@moves = ( new Move('c2^' )  );        warn "DEBUG ONLY\n";

    foreach my $move (@moves) {
        my $new_board = $board->clone;
        $num_moves++;
        $move->apply($new_board)
            or next;
        #$new_board->display;            warn "DEBUG ONLY\n";
        if ($new_board->has_won) {
            return [$move];
        }

        next if ($depth_remaining <= 0);
        next if $seen->{ $new_board->hash }++;
        $num_boards++;
        #next if IsUnsolvable::noclipping_mark1($new_board);
        next if IsUnsolvable::noclipping_mark3($new_board);

        $display_every_n++;
        if ($display_every_n % 500 == 0) {
            $new_board->display;        # display the board every 1,000 moves
            print_stats();
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
