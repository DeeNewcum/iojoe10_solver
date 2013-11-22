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


memoize('_noclipping');




# "No clipping" refers to the fact that we ignore *where* on the board each piece is, and pretend
# for a moment that every piece can float around freely.  If the pieces still can't find a match
# given unrestricted movement, then the current board is obviously unsolvable.
#
#
# Returns:
#       true        Board is definitely unsolvable.
#       false       Board may be solvable or unsolvable, we can't determine that.
sub noclipping {
    my ($board) = @_;

    return _noclipping( _list_pieces($board) );
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
        sub NOCLIPPING_DEBUG {0}
sub _noclipping {
    my (@pieces) = @_;

    if (scalar(grep {$_ != 0 && $_ != 10} @pieces) == 0) {
        return 0;       # base case
    }

    my $indent;
    if (NOCLIPPING_DEBUG) {
        my $depth = 10 - scalar(@pieces);
        $indent = "  "x$depth;
    }

    # generate all possible pairs in this list
    for (my $pair1=0; $pair1<@pieces; $pair1++) {
        for (my $pair2=@pieces-1; $pair2>$pair1; $pair2--) {
            my $sum = Move::_combine_pieces( $pieces[$pair1], $pieces[$pair2] );
            next if (!defined($sum));        # skip this pairing if the sum is > 10

            if (NOCLIPPING_DEBUG) {
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

            my $ret = _noclipping( @new_pieces );

            print "${indent}YAY!\n" if (NOCLIPPING_DEBUG && !$ret);

            return 0        if (!$ret);     # We can stop searching right now.  We found at least
                                            # one possible combination of pieces that's a solution.
        }

        # We also want to try to just remove ths one piece, if it's possible to win without
        # combining it.
        if (Move::_can_win_without_combining($pieces[$pair1])) {
            my @new_pieces = @pieces;
            splice @new_pieces, $pair1, 1,  ();
            my $ret = _noclipping( @new_pieces );
            return 0        if (!$ret);
        }
    }

    print "${indent}BOO\n"      if NOCLIPPING_DEBUG;

    return 1;       # We tried every possible combination, and none of them were solutions.
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



1;
