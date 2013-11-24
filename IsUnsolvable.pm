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
    use Time::HiRes qw( time );

    use Data::Dumper;


memoize('_noclipping');


my $total_time = 0;


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

    my $started = time();

    my $ret = _noclipping( _list_pieces($board) );

    my $elapsed = int((time() - $started) * 1000);       # in milliseconds
    $total_time += $elapsed;
    #print "IsUnsolvable::noclipping() took $elapsed ms\n"      if $elapsed > 50;       # display time for single calls
    return $ret;
}

END {
    printf "IsUnsolvable::noclipping() took %.2f seconds total\n", $total_time / 1000;
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
#       This algorithm is seemingly less than ideal. A better algorithm is something like described in
#       The Art of Computer Programming, section 7.2.1.4.  However, the entire section 7.2 makes my
#       brain melt.             http://www.cs.utsa.edu/~wagner/knuth/
#
#       However, this algorithm still functions optimally!  This is because we need to memoize it,
#       because the caller calls us a lot with the same inputs.  Amazing bonus -- memoizing it also
#       fixes the problems with its inefficiency.
#
#           (note to self: if I DO want to understand TAOCP s7.2.1.4, talk to the folks at
#                          https://groups.google.com/forum/#!forum/ps1-moo  )
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

    if (!$ARGV{'--disable-noclipping-shortcut'}) {
        return 0 if (!_noclipping_shortcut(@pieces));
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


# This routine's arguments and return value are exactly the same as _noclipping.
#
# _noclipping() considers *every* possible pairing of numbers.  That's O(n^2), so it can take
# considerable CPU time when n is large.
#
# The full enumeration is definitely warranted in some cases, particularly when negative numbers /
# inverts / multiplies are present.  However, often the full enumeration isn't necessary, often
# we can spot right away that there's a 6+4 or 9+1 pairing, and remove those right away, thereby
# making a quick reduction in n.
#
# We then check to see if this quick reduction results in a solution.  If it does, then we're
# golden -- we don't have to check the full enumeration because we know the set isn't unsolvable.
#
# If the reduction DOESN'T work, then we just fallback to doing the full enumeration.
# For example, even if there's a 6+4 combination, sometimes the 4 really needed to combine with the
# invert block instead.  That's fine if that happens, we can fallback to the full enumeration in
# that case, but that's rare.  In the most usual case, the shortcut will save us a lot of time.
sub _noclipping_shortcut {
    my (@pieces) = @_;

    my %pieces = _uniq_c(@pieces);

    # We could write an algorithm that calculates these.  ... but it's a lot faster to manually 
    # enter them.   The algorithm is a lot longer than manually entering the list:
    #                   http://homepages.ed.ac.uk/jkellehe/partitions.php
    my @combinations = map { [split ' '] } split /\n/, <<'EOF';
            9 1
            9 -1 2
            8 2
            7 3
            6 4
            5 5
            5 3 2
            4 3 3
EOF
    OUTER: foreach my $comb (@combinations) {
        my %new_pieces = %pieces;
        foreach my $c (@$comb) {
            if (!$new_pieces{$c}) {
                next OUTER;
            }
            $new_pieces{$c}--;
        }

        #print "trying ", join(" + ", @$comb), "\n";

        # We found a pair that combines to form 10.  Check to see if this solution works.
        #my @new_pieces = sort(_inverse_uniq_c(\%new_pieces));
        #print "trying -- ", join(" ", @new_pieces), "\n";
        my $ret = _noclipping(sort(_inverse_uniq_c(\%new_pieces)));

        #print "Found a match -- ", join(" ", @$comb), "\n";
        #my $ret = 1;
        
        #!$ret and print "found a solution using the shortcut:    ", join(" + ", @$comb), "\n";

        return 0 if (!$ret);        # That works!  We saved some time!
    }

    #print "Couldn't find a shortcut when examining -- ", join(" ", @pieces), "\n";

    return 1;       # We didn't find any combination that works.  Fallback to the full enumeration.
}

### unit test for _noclipping_shortcut() ####
                # example call:     perl ./IsUnsolvable.pm  8 2 7 3 5 5
#print "final answer -- ",_noclipping_shortcut( @ARGV ) ? "no solution\n" : "found a solution\n";



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

    # Does the inverse of _uniq_c() -- it takes a hash in, and returns a list
    sub _inverse_uniq_c {
        my ($hash) = @_;
        my @list;
        while (my ($var, $val) = each %$hash) {
            for (my $ctr=0; $ctr<$val; $ctr++) {
                push @list, $var;
            }
        }
        return @list;
    }


1;
