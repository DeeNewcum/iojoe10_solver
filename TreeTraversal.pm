package TreeTraversal;

    use strict;
    use warnings;

    use Board;
    use Move;
    use IsUnsolvable;

    use List::PriorityQueue;
    use Time::HiRes qw( time );
    use Data::Dumper;

my $num_moves = 0;      # the number of times that Move::apply() has been called
my $num_boards = 0;     # the number of unique board configurations we've evaluated so far
my $started;
my $display_every_n = 0;
my $display_every_n_secs = 0;


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
    my $elapsed_str;
    if ($elapsed < 20) {
        $elapsed_str = sprintf "%.2f seconds", $elapsed;
    } else {
        $elapsed_str = sprintf "%d:%02d", int($elapsed / 60), int($elapsed) % 60;
    }
    printf "         %12s moves,   %8s boards,   %15s,   %d microseconds per move\n",
                commify($num_moves),
                commify($num_boards),
                $elapsed_str,
                1000000 * $elapsed / ($num_moves + 1);
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
        next if $seen->{ $new_board->fingerprint }++;
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


    # given a node, generate a list of the nodes that are one step away from this node0
    sub _get_neighbors {
        my ($board) = @_;
        my @neighbors;
        for my $move (@{ list_available_moves($board) }) {
            my $new_board = $board->clone;
            $move->apply($new_board)
                or next;
            $num_moves++;
            $new_board->{came_from} = $board;
            $new_board->{came_from_move} = $move;
            push @neighbors, $new_board;
        }
        return @neighbors;
    }

    sub ASTAR_DEBUG { 0 }

sub A_star {
    my ($board) = @_;

    my $open_set = new List::PriorityQueue;
    my %closed_set;
    my %seen;       # Keeps track of which nodes we've seen, and of the mapping from
                    # fingerprint-string => object.  I was having difficulties integrating this into
                    # $open_set and %closed_set, so for now it will be separate.

    $started = time();

    my $fgrprnt = $board->fingerprint;
    $seen{ $fgrprnt } = $board;
    $board->{g} = 0;
    $board->{f} = $board->{h} = heuristic($board);
    $open_set->insert($fgrprnt, $board->{f});

    my $we_reached_the_end;
    OUTER: while (1) {
        $fgrprnt = $open_set->pop();       # get the node with the lowest number from the priority queue
        last if (!defined($fgrprnt));       # no nodes in the queue
        my $current = $seen{ $fgrprnt };

        $current->display       if ASTAR_DEBUG;
        my $t = time();
        if ($t - $display_every_n_secs > 3) {
            $display_every_n_secs = $t;
            $current->display;
                my $duration = int(time - $started);
            print "\t\tf = $current->{f}\t\tg = $current->{g}\t\th = $current->{h}\n";
                    #sprintf "%d:%02d\n", int($duration / 60), $duration % 60;
            print_stats();
        }

        for my $neighbor (_get_neighbors($current)) {
            next if IsUnsolvable::noclipping($neighbor);
            $neighbor->display       if ASTAR_DEBUG;
            if ($neighbor->has_won) {
                $we_reached_the_end = $neighbor;
                last OUTER;
            };
            $neighbor->{g} = $current->g + 1;
            if (!defined($neighbor->h)) {
                $neighbor->{h} = heuristic($neighbor);
            }
            $neighbor->{f} = $neighbor->g + $neighbor->h;
            print "\t\tf = $neighbor->{f}\n",
                  "\t\tg = $neighbor->{g}\n",
                  "\t\th = $neighbor->{h}\n"        if ASTAR_DEBUG;

            my $fingerprint = $neighbor->fingerprint;
            if (exists $seen{$fingerprint}) {
                my $other_copy = $seen{$fingerprint};
                next if ($other_copy->f <= $neighbor->f);
            } else {
                $num_boards++;
            }

            $seen{$fingerprint} = $neighbor;
            $open_set->insert( $fingerprint, $neighbor->f );
        }

        $closed_set{ $current->fingerprint } = 1;
    }
    if (defined($we_reached_the_end)) {
        my @move_list;
        while (defined($we_reached_the_end)) {
            unshift(@move_list, $we_reached_the_end->came_from_move)
                    if defined($we_reached_the_end->came_from_move);
            $we_reached_the_end = $we_reached_the_end->came_from;
        }
        return \@move_list;
    } else {
        return undef;
    }
}


# Come up with the best estimate we can for how far we are from the 
sub heuristic {
    my ($board) = @_;

    #return 0;       # revert to Dijkstra's algorithm

    my @combinable_pieces = IsUnsolvable::_list_pieces($board);
    return scalar(@combinable_pieces);      # the number of pieces that are out of place
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
    print "\t\t\t", join(' ', map {$_->toString} @$moves), "\n";
}



# add commas to a number
sub commify {(my$text=reverse$_[0])=~s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;scalar reverse$text}


1;
