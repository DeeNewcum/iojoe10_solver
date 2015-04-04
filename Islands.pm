# Sometimes the board gets permanently split in two (or three, four, etc) sections.
# When this happens, it's useful to analyze these sections separately.

package Islands;

    use strict;
    use warnings;

    use Board;
    use Move;
    use IsUnsolvable;

    use Time::HiRes qw( time );

    use Data::Dumper;



# If a wall has split the numerical pieces into two or more totally separate groups, then find those
# groups, and call noclipping() on each separate group.
#
# Returns true if it's unsolvable, false if it's solvable.
sub islands {
    my ($board) = @_;
    
    my $immobile_grid = _islands_calculate_immobile($board);

    # do a flood-fill everywhere that there's a combinable piece
    my $num_islands = 0;
    for (my $y=0; $y<$board->{height}; $y++) {
        for (my $x=0; $x<$board->{width}; $x++) {
            next unless (Move::_is_piece_combinable( $board->at($y, $x) ));
            if ($immobile_grid->[$y][$x] == 0) {
                $num_islands++;
                _islands_flood_fill($immobile_grid, $y, $x, $num_islands + 1);
                #print _immobile_grid_toString($immobile_grid), "\n";
            }
        }
    }
    #print _immobile_grid_toString($immobile_grid); #exit;

    return 0    if ($num_islands <= 1);             # there's zero or one islands...  nothing special to check

    ## ==== TODO -- Memoize, right at this point.  Probably store it as a member of $board too.  ====

    # gather up the pieces for each island, and check them separately
    foreach my $color (2 .. $num_islands+1) {
        my @pieces;
        for (my $y=0; $y<$board->{height}; $y++) {
            for (my $x=0; $x<$board->{width}; $x++) {
                my $cell = $board->at($y, $x);
                if ($immobile_grid->[$y][$x] == $color
                   && Move::_is_piece_combinable($cell))
                {
                    push @pieces, $cell;
                }
            }
        }
        #print "island $color:     ", join(" ", @pieces), "\n";
        if (IsUnsolvable::_noclipping(@pieces)) {
            return 1;
        }
    }
    return 0;
}


sub _islands_flood_fill {
    my ($grid, $start_y, $start_x, $color) = @_;            # 0 = mobile, 1 = immobile, 2/3/4/...  "colors" for each unique region

    my $width = scalar(@{$grid->[0]});
    my $height = scalar(@$grid);

    my @queue;
    push @queue, [$start_y, $start_x];
    while (@queue) {
        my ($y, $x) = @{shift @queue};
        next if ($grid->[$y][$x] != 0);
        $grid->[$y][$x] = $color;
        foreach my $dir (1..4) {
            my $y2 = $y + $Move::direction[$dir][0];
            my $x2 = $x + $Move::direction[$dir][1];
            if ($x2>=0 && $x2<$width && $y2>=0 && $y2<$height) {
                push @queue, [$y2, $x2];
            }
        }
    }
}


# Walls are obviously immobile.  But what about sliders?  Sometimes a slider has gotten wedged in a
# place that ensures it's permanently immobile.  But there are ripple effects:
#           XX <<  .  5
#           XX ^^  .  .
#            .  . XX XX
#            5  .  .  .
# Although the up-slider isn't pinned directly against a wall, it IS pinned against another slider
# that itself is immobile.
sub _islands_calculate_immobile {
    my ($board) = @_;

    # initialize the grid
    my @immobile_grid;              # 1 = immobile, 0 = mobile
    for (my $y=0; $y<$board->{height}; $y++) {
        for (my $x=0; $x<$board->{width}; $x++) {
            $immobile_grid[$y][$x] = ($board->at($y, $x) == 10) ? 1 : 0;
        }
    }

    while (1) {
        # This is a suboptimal algorithm for now...   we can speed it up later if needed
        #       (eg. using a queue to maintain a list of cells that need to be checked again)
        my $anything_changed = 0;
        for (my $y=0; $y<$board->{height}; $y++) {
            for (my $x=0; $x<$board->{width}; $x++) {
                my $slider = $board->at( $y, $x );
                if (!$immobile_grid[$y][$x] && exists $Move::sliding_blocks{$slider}
                     && _islands_is_slider_immobile($y, $x, $board, \@immobile_grid))
                {
                    $anything_changed++;
                    $immobile_grid[$y][$x] = 1;
                }
            }
        }
        last unless $anything_changed;
    }

    return \@immobile_grid;
}


# returns true=immobile, false=mobile
sub _islands_is_slider_immobile {
    my ($y, $x, $board, $grid) = @_;

    my $slider_piece = $board->at($y, $x);

    # Look through all the directions this slider could possibly go.  Is there a direction that this
    # piece can move?
    #print "Checking slider ";
    #Board::display_one_piece($slider_piece);
    #print "\n";
    foreach my $dir (@{$Move::sliding_blocks{$slider_piece}}) {
        # Are we able to move one block in this direction?
        my $y2 = $y + $Move::direction[$dir][0];
        my $x2 = $x + $Move::direction[$dir][1];
        #print "  dir $dir lands at ($x2, $y2)\n";
        next if (!Move::_in_bounds($board, $y2, $x2));
        next if ($grid->[$y2][$x2]);
        # We found a way that this slider could move!  So....  it's not immobile.
        if (1) {
            my $m = new Move(x => $x, y => $y, dir => $dir);
            #print "  this piece can move ", $m->toString(), ", so it isn't immobile\n";
        }
        return 0;
    }
    #print "  couldn't find a way for this piece to move\n";

    return 1;       # We couldn't find any direction that we could move.
}


# just for debugging pruposes
sub _immobile_grid_toString {
    my ($grid) = @_;
    my $str = '';
    foreach my $row (reverse @$grid) {
        foreach my $col (@$row) {
            $str .= ($col == 0 ? "." :
                    ($col == 1 ? "X" : $col));
        }
        $str .= "\n";
    }
    return $str;
}


1;
