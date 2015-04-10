#!/usr/bin/perl

# tests for:
#   - IsUnsolvable::islands() and related functions


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::More tests => 6;

    use IsUnsolvable;
    use Board;
    use Move;
    use Islands;

    use Data::Dumper;


my $board_2islands = Board::new_from_string(<<'EOF');
           XX <<  2  1
           XX ^^  .  .
            .  . XX XX
            3  4  .  .
EOF

my $board_1island = Board::new_from_string(<<'EOF');
           XX  .  2  1
           XX ^^  .  .
            .  . XX XX
            3  4  .  .
EOF


ok(verify_island_shape( $board_2islands->{islands}, <<'EOF' ),  "shape: \$board_2islands bottom-left");
    ....
    ....
    XX..
    XXXX
EOF

ok(verify_island_shape( $board_2islands->{islands}, <<'EOF' ),  "shape: \$board_2islands top-right");
    ..XX
    ..XX
    ....
    ....
EOF

is(Islands::_toString(
    Islands::_islands_calculate_immobile($board_2islands)), trim(<<'EOF'), 'immobile grid for 2islands');
            XX..
            XX..
            ..XX
            ....
EOF

is(Islands::_toString(
    Islands::_islands_calculate_immobile($board_1island)), trim(<<'EOF'), 'immobile grid for 1islands');
            X...
            X...
            ..XX
            ....
EOF


ok($board_2islands->{islands}->noclipping($board_2islands),     "2islands is unsolvable");
ok(!$board_1island->{islands}->noclipping($board_1island),      "1island is solvable");



sub verify_island_shape {
    my ($island, $island_shape) = @_;

    my @shape =
            map { [ unpack "(A1)*", $_ ] }
              reverse
                split /[\n\r]+/s,
                  trim($island_shape);

        #!print Dumper \@shape;

    ## There may be multiple islands.  Figure out which one might match this one.
    my $island_num;
    my $height = scalar( @shape );
    my $width = scalar( @{ $shape[0] } );
    for (my $y=0; $y<$height; $y++) {
        for (my $x=0; $x<$width; $x++) {
            # Locate the first point.
            if ($shape[$y][$x] eq 'X') {
                my $isl = $island->{grid}[$y][$x];
                # Is there an island here?
                if (!defined($isl) || $isl < 2) {
                    return 0;
                }
                $island_num = $isl;
                $y = 999;
                last;
            }
        }
    }

    ## Verify that the shape matches exactly
    for (my $y=0; $y<$height; $y++) {
        for (my $x=0; $x<$width; $x++) {
            if (($shape[$y][$x] eq 'X')
                    != ($island->{grid}[$y][$x] == $island_num))
            {
                return 0;
            }
        }
    }
    
    return 1;
}



sub trim { (my $a=shift) =~ s/^\s+|\s+$//mg; "$a\n" }
