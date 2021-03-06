package TreeTraversal;

    use strict;
    use warnings;

    use Board;
    use Move;
    use IsUnsolvable;
    use Islands;

    use List::PriorityQueue;
    use List::Util;
    use Time::HiRes qw( time );
    use Data::Dumper;

my $num_moves = 0;      # the number of times that Move::apply() has been called
my $num_boards = 0;     # the number of unique board configurations we've evaluated so far
my $started;
my $display_every_n = 0;
my $display_every_n_secs = 0;
my $avgdepth_ctr = 0;
my $avgdepth_sum = 0;


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


# breadth-first search
sub BFS {
    my ($starting_board) = @_;

    $num_moves = 0;
    $started = time();
    my $display_every_n_secs = time();

    my @queue = ($starting_board);
    my %seen;

    my $winner;
    OUTER: while (@queue) {
        my $board = pop @queue;

        my $t = time();
        if ($t - $display_every_n_secs > 3
                    && ! $INC{'Test/Builder/Module.pm'}) {     # don't display when running under 'prove' or Test::Simple or Test::More
            $display_every_n_secs = $t;
            $board->display;
            print_stats("", $starting_board);
        }

        my @neighbors = _get_neighbors($board);
        foreach my $new_board (@neighbors) {
            if ($new_board->has_won) {
                $winner = $new_board;
                last OUTER;
            }
            my $f = $new_board->fingerprint;
            next if $seen{$f}++;

            $avgdepth_ctr++;
            $avgdepth_sum += $new_board->{g};

            $num_boards++;
            unshift @queue, $new_board;
        }
    }

    return undef unless $winner;        # no solution could be found

    return $winner->{came_from_moves};
}


# iterative deepening depth-first search
sub IDDFS {
    my ($board) = @_;

    $num_moves = 0;
    $started = time();

    for (my $depth=1;  ; $depth++) {
        print "==== trying to depth $depth ====\n";

        my %seen;
        my $ret = _IDDFS($board, $depth, \%seen, []);
        return $ret if defined($ret);

        print_stats();

        #die "quitting after first round\n";
    }

    return undef;
}

# show the stats so far
sub print_stats {
    my ($additional_text, $starting_board) = @_;
    $additional_text = "" unless defined($additional_text);

    my $elapsed = time() - $started;
    my $elapsed_str;
    if ($elapsed < 20) {
        $elapsed_str = sprintf "%.2f seconds", $elapsed;
    } else {
        $elapsed_str = sprintf "%d:%02d", int($elapsed / 60), int($elapsed) % 60;
    }

    if ($avgdepth_ctr > 0 && !$additional_text) {
        my $avgdepth_str = sprintf ",   avg depth %.1f", $avgdepth_sum / $avgdepth_ctr;
        $avgdepth_str =~ s/\.\d$//      if ($ARGV{'--bfs'});
        $avgdepth_str .= " of $starting_board->{file_fields}{shortest_solution}"
                if ($starting_board && $starting_board->{file_fields}{shortest_solution});
        $additional_text = $avgdepth_str . $additional_text
    }
    $avgdepth_sum = $avgdepth_ctr = 0;

    printf "         %12s moves,   %8s boards,   %15s,   %d microseconds per move%s\n",
                commify($num_moves),
                commify($num_boards),
                $elapsed_str,
                1000000 * $elapsed / ($num_moves + 1),
                $additional_text;
}


# Returns a list-ref of moves, if a solution was found.
my $iddfs_wasted = 0;
END {
    print "iddfs_wasted = $iddfs_wasted\n"  if $iddfs_wasted;
}
sub _IDDFS {
    my ($board, $depth_remaining, $seen, $dbg_move_list) = @_;

    #print move_list_toString($dbg_move_list), "\n";

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

        # %$seen remembers the depth that we encountered each board at.  If we encounter the same
        # board, but at a shallower depth, then keep going anyway, since that will result in a
        # shorter solution.
        my $fgpt = $new_board->fingerprint;
        $iddfs_wasted++ if (exists $seen->{$fgpt} && -$depth_remaining < $seen->{$fgpt});
            # This paragraph is kind of wasteful, because even if we continue from an earlier node,
            # we still recompute the entire path over again!  Implementing BFS whould resolve these
            # problems.         ($iddfs_wasted is up to 100% of the solution moves)
            #           (eg. Inverting-5 takes for-fuckin-ever)
        next if (-$depth_remaining >= ($seen->{$fgpt} || 0));
        $seen->{$fgpt} ||= -$depth_remaining;     
    
        $num_boards++;
        next if IsUnsolvable::noclipping($new_board);

        $display_every_n++;
        if ($display_every_n % 500 == 0) {
            $new_board->display;        # display the board every 1,000 moves
            print_stats();
        }

        my $ret = _IDDFS( $new_board, $depth_remaining - 1, $seen, [@$dbg_move_list, $move]);
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
            my $apply_loc = $move->apply($new_board)
                or next;
            $num_moves++;
            my $piece = $new_board->at(@$apply_loc);       # the piece when we finished moving
            if ($piece == 10 || ($piece % 100 == 0 && $piece >= 100 && $piece <= 700)) {
                # We've created a new wall, or moved a slider. Therefore it's possible we've created
                # a new island.  Update the island shapes.
                $new_board->{islands} = Islands->new($new_board);
                if ($new_board->{islands}{num_islands} > 1) {
                    $new_board->{islands}->dump(  $new_board  );
                }
                next if $new_board->{islands}->noclipping( $new_board );
            }
            $new_board->{came_from_moves} = [ @{$board->{came_from_moves} || []}, $move ];
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
        if ($t - $display_every_n_secs > 3
                    && ! $INC{'Test/Builder/Module.pm'}) {     # don't display when running under 'prove' or Test::Simple or Test::More
            $display_every_n_secs = $t;
            $current->display;
                my $duration = int(time - $started);
            print "\t\tf = $current->{f}\t\tg = $current->{g}\t\th = $current->{h}\n";
                    #sprintf "%d:%02d\n", int($duration / 60), $duration % 60;
            print_stats("", $board);
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

            $avgdepth_ctr++;
            $avgdepth_sum += $neighbor->{g};

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
        return $we_reached_the_end->{came_from_moves};
    } else {
        return undef;
    }
}


# Come up with the best estimate we can for how far we are from the 
sub heuristic {
    my ($board) = @_;

    #return 0;       # revert to Dijkstra's algorithm

    my @combinable_pieces = IsUnsolvable::_list_pieces($board);

    # The number of pieces that are out of place, divided by two.
    # (because each move could at most result in two out-of-place pieces being combined into walls)
    # A concrete example:   Simple-8 has 14 pieces out of place, but requires only 8 moves to solve.
    my $heuristic = scalar(@combinable_pieces) / 2;      

    $heuristic *= ($ARGV{'--relax'} || 1);        # bounded relaxation -- weighted A*

    return $heuristic;
}


# After a solution is found, go through and calculate which pieces got combined together.
#
# This can be useful to display to the user.  It's also useful in automated testing.
#
# Returns a list-of-lists, where:
#       - The outer list is the group that got combined together.  Its contents should always
#         combine to be 10  (or -10).
#         Note though that pieces that didn't get combined (see _can_win_without_combining()),
#         they will be left in a group of their own.
#       - The inner list contains individual pieces.  The variable-type of a piece is the same type
#         that's used in Board::cells.
#         The order of this list is the order that they were combined in.
sub get_combined_groups {
    my ($move_list, $board) = @_;

    $board = $board->clone;     # don't corrupt the one that was passed to us

    my $width = $board->width;
    my $height = $board->height;

    # We're going to go through the sequence of moves in a minute.  While we're doing that,
    # the group information will live on a grid.
    #
    # Early on, there will be many groups, but they will get consolidated as groups get combined
    # during each move.
    my @grid_groups;
    for (my $y=0; $y<$height; $y++) {
        for (my $x=0; $x<$width; $x++) {
            if (Move::_is_piece_combinable( $board->{cells}[$y][$x] )) {
                # at the beginning, each group just contains the piece that it started with
                $grid_groups[$y][$x] = [ $board->{cells}[$y][$x] ];
            } else {
                $grid_groups[$y][$x] = undef;
            }
        }
    }

    # Make each move, and remember which groups got combined.
    foreach my $move (@$move_list) {
        my $last_board = $board->clone;
        my ($y1, $x1) = ($move->y, $move->x);           # position before the move
        my ($y2, $x2) = @{ $move->apply($board) };      # position after the move
        next if ($last_board->at($y1, $x1) % 100 == 0);     # movable blocks don't combine
        my $combined_with = $last_board->at($y2, $x2);  # what piece was at this location, just before the move?
        # combine the two groups
        if ($combined_with >= 49 && $combined_with <= 59) {
            # Whenever we multiply something, we have to wrap it in parentheses, because we're using
            # infix notation.
            unshift @{ $grid_groups[$y2][$x2] }, 
                       $grid_groups[$y1][$x1];
        } else {
            unshift @{ $grid_groups[$y2][$x2] }, 
                    @{ $grid_groups[$y1][$x1] };
        }
        $grid_groups[$y1][$x1] = undef;
    }

    # Pull the groups out of the grid, put them into a plain list.
    my @group_list;
    for (my $y=0; $y<$height; $y++) {
        for (my $x=0; $x<$width; $x++) {
            if (defined($grid_groups[$y][$x])) {
                push @group_list, $grid_groups[$y][$x];
            }
        }
    }

    # For pieces that went totally uncombined (because they weren't *required* to be combined 
    # before the board could be won), don't display those pieces.       (they appear here as one-length groups)
    @group_list = grep { !( scalar(@$_) == 1 && ref($_->[0]) eq '') } @group_list;

    # The order of the groups is arbitrary, but it can be nice to sort them.
    @group_list = sort {_group_sort($a) <=> _group_sort($b)
                            || _group_subsort($b) <=> _group_subsort($a)
                       } @group_list;

    return @group_list;
}
        # Shorter groups first, then the longer groups, followed by groups that didn't get combined.
        sub _group_sort {
            my ($group) = @_;
            return (scalar(@$group) == 1) ? 99 : scalar(@$group);
        }
        # Within groups that are equally long, sort by the maximum NUMERICAL block in the group.
        sub _group_subsort {
            my ($group) = @_;
            return (List::Util::max
                        grep {$_ <= 10 && $_ >=-10} @$group)
                   || 0;
        }
            # same as List::MoreUtils::first_index()
            sub _first_index(&@) {
                my ($block, @list) = @_;
                for (my $ctr=0; $ctr<@list; $ctr++) {
                    local $_ = $list[$ctr];
                    if ($block->()) {
                        return $ctr;
                    }
                }
                return undef;
            }


sub move_list_toString {
    my ($move_list) = shift;

    my $str = '';
    foreach my $move (@$move_list) {
        $str .= $move->toString . "  ";
    }
    return $str;
}


sub display_solution {
    my ($move_list, $orig_board) = @_;

    my $board = $orig_board->clone;     # don't corrupt the one that was passed to us

    $board->display;

    foreach my $move (@$move_list) {
        $move->apply($board);
        print "  " x ($board->width + 3), $move->toString, "\n";
        $board->display;
        print "\n";
    }

    if ($orig_board->{file_fields}{filename}) {
        (my $f = $orig_board->{file_fields}{filename})      =~ s#^.*/##;
        print "========[ $f solution ]=======\n\n";
    }
    $orig_board->display;
    print "\t\t\t", join(' ', map {$_->toString} @$move_list), "\n";

    my @groups = get_combined_groups($move_list, $orig_board);
    
    ## display the groups
    print "\nPieces that combined:\n";
    foreach my $group (@groups) {
        print "\t";
        _display_group($group);
        print "\n\n";
    }
}


    sub _display_group {
        my ($group) = @_;

        my $first = 1;
        for (my $ctr=0; $ctr<@$group; $ctr++) {
            my $piece = $group->[$ctr];
            if (ref($piece)) {
                print " + "     if (!$first);
                print "( "      ;#if (@$piece > 1);
                _display_group($piece);
                print " )"      ;#if (@$piece > 1);
            } elsif ($piece >= 49 && $piece <= 59) {
                print " * ", $piece - 50;
            } else {
                print " + "     if (!$first);
                print $piece;
            }
            $first = 0;
        }
    }


# This subroutine is very important.  See docs/TestCore.txt.
# After the solver finds a solution, this is used to verify that a valid solution was found.
# This is used during testing, to confirm that the rest of the program is functioning correctly.
#
# Returns true if the solution was verified, false if it couldn't be verified.
sub verify_solution {
    my ($board, $move_list) = @_;

    my $original_board = $board;
    $board = $board->clone;         # don't modify our inputs

    # go through the list of moves, and confirm each is a legal move
    foreach my $move (@$move_list) {
        my $ret = $move->apply($board);
        if (!$ret) {
            my $mv = $move->toString;
            warn "SERIOUS ERROR -- move  '$mv'  within solution is an illegal move\n\t"
                    unless $ENV{HARNESS_ACTIVE};
                    #unless $INC{'Test/Builder/Module.pm'};      # don't display when running under 'prove' or Test::Simple or Test::More
            return 0;
        }
    }

    # confirm that after applying all moves, that the final board position is a winning position
    if (!$board->has_won) {
        warn "SERIOUS ERROR -- after applying all moves, the final board position is not a winning position\n\t"
                    unless $ENV{HARNESS_ACTIVE};
                    #unless $INC{'Test/Builder/Module.pm'};
        return 0;
    }

    # confirm that the solution is an optimal length   (if the shortest_solution: field is present)
    if (exists $board->{file_fields}{shortest_solution}) {
        if (scalar(@$move_list) > $board->{file_fields}{shortest_solution}) {
            return 0;
        }
    }

    return 1;
}



# add commas to a number
sub commify {(my$text=reverse$_[0])=~s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;scalar reverse$text}


1;
