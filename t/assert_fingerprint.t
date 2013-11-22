#!/usr/bin/perl

# assertions that are checked here:
#   - %Board::to_fingerprint doesn't have duplicate values for different inputs
#
#   - %Board::to_fingerprint has only single-character outputs


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 2;
    use Board;

    use Data::Dumper;


# ASSERTION -- %Board::to_fingerprint doesn't have duplicate values for different inputs
if (1) {
    my %seen;
    my $has_duplicate = 0;
    foreach my $value (values %Board::to_fingerprint) {
        if ($seen{$value}++) {
            warn "duplicate failed for -- $value\n";
            $has_duplicate++;
            last;
        }
    }
    ok(!$has_duplicate, "\%Board::to_fingerprint shouldn't have any duplicate values");
}



# ASSERTION -- %Board::to_fingerprint's outputs are only a single character wide
#                   (this also helps to ensure that Board::fingerprint() can't have hash-collisions)
if (1) {
    my %seen;
    my $has_multichar = 0;
    foreach my $value (values %Board::to_fingerprint) {
        if (length($value) > 1) {
            $has_multichar++;
            last;
        }
    }
    ok(!$has_multichar, '%Board::to_fingerprint has single-character values');
}
