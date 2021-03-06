# Sometimes the board gets permanently split in two (or three, four, etc) sections.
# When this happens, it's useful to analyze these sections separately.


# TODO:
#
#   - _islands_calculate_immobile() fails to detect this condition:
#
#             . >>  2
#             .  . XX
#
#     because it doesn't realize that the "2" itself is immobile.
#     Two questions:  1) is this important enough that we do need to detect it?  2) if we do, then how exactly do we do this?

package Islands;

    use strict;
    use warnings;

    # We have to avoid a dependency-loop, so we just assume these are already loaded.
    #               http://stackoverflow.com/questions/3428264/perl-subroutine-redefined
    #use Board;
    #use Move;
    #use IsUnsolvable;

    use Term::ExtendedColor ':attributes';
    use Time::HiRes qw( time );

    use Data::Dumper;


# Calculates the shape of each island.  This should be cached across boards, and updated only when
# there's reasonable suspicion that the island shape may have changed.
sub new {
    my $class = shift;
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
                #print _toString($immobile_grid), "\n";
            }
        }
    }
    #print _toString($immobile_grid); #exit;

    return bless {
            grid        => $immobile_grid,
            num_islands => $num_islands,
        }, $class;
}


# Calls IsUnsolvable::noclipping() on each island.
#
# Returns true if it's unsolvable, false if it's solvable.
sub noclipping {
    my ($self, $board) = @_;
    
    #return 0    if ($self->{num_islands} <= 1);             # there's zero or one islands...  nothing special to check

    # gather up the pieces for each island, and check them separately
    foreach my $color (2 .. $self->{num_islands}+1) {
        my @pieces;
        for (my $y=0; $y<$board->{height}; $y++) {
            for (my $x=0; $x<$board->{width}; $x++) {
                my $cell = $board->at($y, $x);
                if ($self->{grid}[$y][$x] == $color
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
    my ($grid, $start_y, $start_x, $color) = @_;            # 0 = mobile,  1 = immobile,  2/3/4/...  "colors" for each unique region

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
            #print "  this piece can move ", $m->_toString(), ", so it isn't immobile\n";
        }
        return 0;
    }
    #print "  couldn't find a way for this piece to move\n";

    return 1;       # We couldn't find any direction that we could move.
}


# for testing in t/islands.t
sub _toString {
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


# for debugging
INIT {
    no warnings 'redefine';
    *TreeTraversal::display_solution = sub {exit};          # FOR DEBUGGING ONLY -- once we get to the part where we display a solution, exit so the Islands::dump() output can be more easily seen.
}
sub dump {
    my ($self, $board) = @_;

    if (!defined($board)) {         # $board is optional, if it's not included, we'll just dump the islands data
        if (!defined($self)) {
            print "ERROR -- \$self = null\n";
        }
        printf "---- \$num_islands = %s\n", defined($self->{num_islands}) ? $self->{num_islands} : "<undef>";
        print _toString( $self->{grid} );;
    } else {
        #die "TODO\t";
        # # display_one_piece()
        my @island_colors = (
                "gray1/7",              # not marked as either an island or immobile
                "red1/3",               # immobile per _islands_calculate_immobile()
                "blue1/10",             # island #1
                "green1/18",            # island #2
                "purple4/10",           # island #3
                "orange1/3",            # island #4
        );

        for (my $y=$board->height-1; $y>=0; $y--) {
            for (my $x=0; $x<$board->width; $x++) {
                my $piece = sprintf "%2s", Board::piece_toString( $board->at($y, $x) );

                my $island_num = $self->{grid}[$y][$x];
                my $bg = $island_colors[ $island_num ];
                my $odd = ($x + $y) % 2;
                if ($odd) {
                    $bg =~ s#\d.*/##;
                } else {
                    $bg =~ s#/.*##;
                }
                #my $fg = ($island_num == 1) ?
                #        'gray1' :       # foreground-color = white,   for immobile blocks;
                #        'gray24';       # foreground-color = black    normally
                my $fg = 'gray24';
                print fg($fg, bg($bg,  $piece));
            }
            print "\n";
        }
        print "\n";
    }
}


1;
