# Routines that try to determine if the current board position is unsolvable.
#
# It's important to detect when we've hit a dead-end as soon as possible, so we can back out and try
# another way.


package IsUnsolvable;

    use strict;
    use warnings;

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

    # make a list of all the numberical pieces that are still free
    my @pieces;
    for (my $y=0; $y<$self->height; $y++) {
        for (my $x=0; $x<$self->width; $x++) {
            my $cell = $self->cells->[$y][$x];
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
    die Dumper \%pieces;

    for my $current_piece (5..9) {
        next unless $pieces{$current_piece};

        if ($current_piece == 5) {
            if ($pieces{5} <
            return 
        }
    }
    # LEFTOFF:   It's somewhat obvious what we do if they're all positive, but what do we do if
    #            there are any negatives?

}

1;
