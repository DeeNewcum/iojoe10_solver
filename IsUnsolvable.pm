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
    use Islands;

    use Memoize;
    use Time::HiRes qw( time );

    use Data::Dumper;


memoize('_noclipping');
memoize('_eqzero_mults');


my $noclipping_calls = 0;
my $noclipping_subcalls = 0;
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

    $noclipping_subcalls = 0;

    my $ret = 0;
    #$ret = Islands::islands($board);

    if (!$ret) {
        $ret = _noclipping( _list_pieces($board) );
    }

    my $elapsed = int((time() - $started) * 1000);       # in milliseconds
    $total_time += $elapsed;
    $noclipping_calls++ if $noclipping_subcalls;
    #if ($elapsed > 10) {            # display time for single calls
    if ($noclipping_subcalls && $ARGV{'--noclipping-verbose'}) {
        printf "call #%d to IsUnsolvable::noclipping() took %-20s  %20s and returned '%s'\n",
            $noclipping_calls,
            TreeTraversal::commify($elapsed) . " ms",
            "and " . TreeTraversal::commify($noclipping_subcalls) . " subcalls",
            ($ret ? "unsolvable" : "solvable");
    }

    return $ret;
}

END {
    printf "IsUnsolvable::noclipping() took %.2f seconds total\n", $total_time / 1000
                    if (!$INC{'Test/Builder/Module.pm'} && $noclipping_calls);      # don't display when running under 'prove' or Test::Simple or Test::More
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

    # Simplify -- remove pieces that don't change the answer.
    @pieces = grep {$_ != 0 && $_ != 10 &&  $_ != -10} @pieces;

    if (scalar(@pieces) == 0) {
        return 0;       # base case -- there are no pieces left, so it's obviously solvable
    }

    my $indent;
    if (NOCLIPPING_DEBUG) {
        my $depth = 10 - scalar(@pieces);
        $indent = "  "x$depth;
    }

    $noclipping_subcalls++;

    return 1 if (!eqzero(\@pieces));

    my $shortcut_ret = _noclipping_shortcut(@pieces);
    return $shortcut_ret if (defined($shortcut_ret));

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
#
#
#
# NOTE: It doesn't really help to be able to say "yes, this is solvable" really quickly, because
#       we process a lot of ultimately unsolvable positions.  If we can't speed those up too, 
#       then the full tree will have to be explored anyway, which means that, a huge amount of the
#       time, we're not providing any speedup.
#
#
# Returns:
#       true        There doesn't exist any combination of pieces that is a solution.
#       false       There does exist at least one possible combination of pieces that is a solution.
#       undef       No shortcut is possible in this case.  A full enumeration is needed.
sub _noclipping_shortcut {
    my (@pieces) = @_;

    # This shortcut can't be used if there are any: 1) invert pieces, 2) multiply pieces, or
    # 3) negative pieces.
    #       ASSERTION: the list of pieces passed to us are IN ORDER
    if (@pieces && ($pieces[-1] > 9 || $pieces[0] < 0)) {
        return undef;
    }

    my %pieces = _uniq_c(@pieces);

    # We could write an algorithm that calculates these.  ... but it's a lot faster to manually 
    # enter them.   The algorithm is a lot longer than manually entering the list:
    #                   http://homepages.ed.ac.uk/jkellehe/partitions.php
    my @combinations = map { [split ' '] } split /\n/, <<'EOF';
            9 1
            8 2
            7 3
            6 4
EOF

    my %new_pieces = %pieces;
    my $shortcut_found = 0;
    OUTER: foreach my $comb (@combinations) {
        foreach my $c (@$comb) {
            if (!$new_pieces{$c}) {
                next OUTER;
            }
        }

        # Okay, this combination is a match.  These pieces add up to 10, so remove them.
        foreach my $c (@$comb) {
            $new_pieces{$c}--;
        }
        $shortcut_found++;
    }

    # If we didn't optimize anything, then revert back to the full enumeration.
    # This is important because it's the recursive base-case, it prevents infinite recursion
    # from happening.
    return undef if (!$shortcut_found);

    # Now that we've simplified the problem, continue solving the problem.
    return _noclipping(sort(_inverse_uniq_c(\%new_pieces)));
}

### unit test for _noclipping_shortcut() ####
                # example call:     perl ./IsUnsolvable.pm  8 2 7 3 5 5
if (0) {
    my $ret = _noclipping_shortcut( @ARGV );
    if (defined($ret)) {
        print "final answer -- ", $ret ? "no solution\n" : "found a solution\n";
    } else {
        print "final answer -- could not take the shortcut\n";
    }
}

if (0) {
    print "final answer -- ",_noclipping( @ARGV ) ? "no solution\n" : "found a solution\n";
}



    sub _list_pieces {
        my ($board) = @_;

        # make a list of all the numberical pieces that are still free
        my @pieces;
        for (my $y=0; $y<$board->{height}; $y++) {
            for (my $x=0; $x<$board->{width}; $x++) {
                my $cell = $board->{cells}[$y][$x];
                if (Move::_is_piece_combinable( $cell )) {
                    push @pieces, $cell;
                }
            }
        }
        @pieces = sort { $a <=> $b }@pieces;
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


# Does this list of pieces total zero (modulo 10)?
# If not, then we combined the wrong piece with a multiply or invert piece.
#
# Returns:
#       true        it *does* total up to zero (modulo 10)
#       false       it doesn't total up to zero (modulo 10) 
our %_eqzero_mult_seen;
sub eqzero {
    my ($pieces) = @_;

    my @mults     = grep {$_ >= 49 && $_ <= 59} @$pieces;           # multiplies / inverts
    my @non_mults = grep {!($_ >= 49 && $_ <= 59)} @$pieces;        # numerical pieces

    # For now, we don't handle cases where there are multiply or invert pieces that are still on the board.
    return 1 if (@mults);

    my $sum = 0;
    map { $sum += $_ } @non_mults;

    return _eqzero_mults( $sum % 10, @mults );
}


sub _eqzero_mults {

    my ($sum, @mults) = @_;

    if (@mults == 0) {
        return ($sum % 10) == 0;
    }
    return 1 if !$ARGV{'--compare-old'};

    my $multiply = pop(@mults) - 50;
    if (@mults == 0) {
        for (my $factor=-9; $factor<=9; $factor++) {
            if (($sum + $factor * $multiply) % 10 == 0) {
                return 1;
            }
        }
    } else {
        for (my $factor=-9; $factor<=9; $factor++) {
            if (_eqzero_mults( $sum + $multiply * $factor, @mults )) {
                return 1;
            }
        }
    }
    return 0;
}



1;
