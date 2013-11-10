# Routines that try to determine if the current board position is unsolvable.
#
# It's important to detect when we've hit a dead-end as soon as possible, since detecting a failed
# path early allows us to avoid the huge number of child-branches that we otherwise would have tried
# to explore.


package IsUnsolvable;

    use strict;
    use warnings;

    use Board;

    use Data::Dumper;


# TODO:
#       - detect when a numerical piece becomes geographically isolated from the others
#               (though this is a bit tricky...   if it's isolated, but still has enough
#                peers in its isolated section to reach 10, then it's still okay)




# "No clipping" refers to the fact that we ignore *where* on the board each piece is, and pretend
# for a moment that every piece can float around freely.  If the pieces still can't find a match
# given unrestricted movement, then the current board is obviously unsolvable.
#
# "Mark1" is the most simplistic approach.  We just look at one piece at a time, and ignore all
# others.  Is there some way that THIS piece and match up with any other piece, ignoring all other
# [competing] pieces?  If there's any piece that isn't true for, then this board is unsovlable.
#
# "Mark2" is slightly more sophisticated.  If there are no negative pieces on the board, then Mark2
# tries to match up all moveable pieces together, but taking into account all other pairings.
# This may be O(n^2), we'll see.  However, if there are any negative pieces on the board, then 
# it gives up.  Mark2 is blind whenever there are negative pieces around.
#
# "Mark3" will hopefully do what Mark2 does, but do its job even when there are negative pieces are
# around.  I have no idea what O() this will be.
#
# Returns true if the board is definitely unsolvable.
# Returns false if it doesn't know if it's solvable or not.
sub noclipping_mark1 {
    my $board = shift;

    my %pieces = _list_pieces($board);

    # If there are any negative pieces, then this algorithm can't handle it.  Give up.
    my @pieces = sort keys %pieces;
    return 0 if ($pieces[0] < 0);

    OUTER:
    for my $current_piece (reverse @pieces) {
        last if ($current_piece < 5);

        for my $match_piece (1..(10 - $current_piece)) {
            if (exists $pieces{$match_piece}) {
                next OUTER;
            }
        }

        return 1;
    }

    return 0;
}


    sub _list_pieces {
        my ($board) = @_;

        # make a list of all the numberical pieces that are still free
        my @pieces;
        for (my $y=0; $y<$board->height; $y++) {
            for (my $x=0; $x<$board->width; $x++) {
                my $cell = $board->{cells}[$y][$x];
                if (abs($cell) >= 1 && abs($cell) <= 9) {
                    push @pieces, $cell;
                }
            }
        }
        @pieces = sort @pieces;
        #die Dumper \@pieces;

        my %pieces;
        foreach my $p (@pieces) {
            $pieces{$p}++;
        }

        return %pieces;
    }

1;
