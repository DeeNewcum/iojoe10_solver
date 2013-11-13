# Routines that try to determine if the current board position is unsolvable.
#
# It's important to detect when we've hit a dead-end as soon as possible, since detecting a failed
# path early allows us to avoid the huge number of child-branches that we otherwise would have tried
# to explore.


package IsUnsolvable;

    use strict;
    use warnings;

    use Board;
    use Move;

    use Memoize;

    use Data::Dumper;


memoize('_noclipping_mark3');


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

    my %pieces = _uniq_c(_list_pieces($board));

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
                if (Move::_is_piece_combinable( $cell )) {
                    push @pieces, $cell;
                }
            }
        }
        @pieces = sort @pieces;
        #die Dumper \@pieces;

        return @pieces;
    }

    # Does the same thing as $(uniq -c)
    # That is, it takes a list in, and returns a hash, where the values of the hash indicate 
    # the number of times that element is repeated.
    sub _uniq_c {
        my (@list) = @_;

        my %hash;
        foreach my $item (@list) {
            $hash{$item}++;
        }

        return %hash;
    }


# Returns:
#       true        Board is definitely unsolvable.
#       false       Board may be solvable or unsolvable, we can't determine that.
sub noclipping_mark3 {
    my ($board) = @_;

    return _noclipping_mark3( _list_pieces($board) );
}



# Parameters:
#       @pieces     The list of pieces (the output of _list_pieces()).
#                   Note: MUST be in sorted order   (for memoization purposes)
#
# Returns:
#       true        There doesn't exist any combination of pieces that is a solution.
#       false       There does exist at least one possible combination of pieces that is a solution.
#
# Commentary:
#       This algorithm is FAR from ideal.  A better algorithm is something like is described in
#       The Art of Computer Programming, section 7.2.1.4.  However, the entire section 7.2 makes my
#       brain melt.             http://www.cs.utsa.edu/~wagner/knuth/
#
#           (note to self: if I DO want to understand TAOCP s7.2.1.4, talk to the folks at
#                          https://groups.google.com/forum/#!forum/ps1-moo  )
#
#       However, I think we can get away with an extremely suboptimal algorithm due to one key
#       thing -- we're memoizing this subroutine.  We need to memoize it anyway, because the caller
#       is going to call us a lot, for basically the same input.  Thus, the memoization serves two
#       purposes -- 1) to help out the caller, and 2) to smooth over the fact that our algorithm
#       is piss-poor.
        sub MARK3_DEBUG {0}
sub _noclipping_mark3 {
    my (@pieces) = @_;

    if (scalar(grep {$_ != 0 && $_ != 10} @pieces) == 0) {
        return 0;       # base case
    }

    my $indent;
    if (MARK3_DEBUG) {
        my $depth = 10 - scalar(@pieces);
        $indent = "  "x$depth;
    }


    # generate all possible pairs in this list
    for (my $pair1=0; $pair1<@pieces; $pair1++) {
        for (my $pair2=@pieces-1; $pair2>$pair1; $pair2--) {
            my $sum = Move::_combine_pieces( $pieces[$pair1], $pieces[$pair2] );
            next if (!defined($sum) || abs($sum) > 10);        # skip this pairing if the sum is > 10

            if (MARK3_DEBUG) {
                printf "%-30s  %s\n",
                        $indent . join(" ", @pieces),
                        "$pieces[$pair1] + $pieces[$pair2] => $sum";
            }

            # make a copy of the list, remove the two pieces, replace with a piece that combines them
            my @new_pieces = @pieces;
            splice @new_pieces, $pair2, 1,  ();
            splice @new_pieces, $pair1, 1,  ();
            @new_pieces = sort {$a <=> $b} (@new_pieces, $sum)
                    unless ($sum == 10 || $sum == 0);

            my $ret = _noclipping_mark3( @new_pieces );

            print "${indent}YAY!\n" if (MARK3_DEBUG && !$ret);

            return 0        if (!$ret);     # We can stop searching right now.  We found at least
                                            # one possible combination of pieces that's a solution.
        }
    }

    print "${indent}BOO\n"      if MARK3_DEBUG;

    return 1;       # We tried every possible combination, and none of them were solutions.
}


1;
