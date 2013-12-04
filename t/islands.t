#!/usr/bin/perl

# tests for:
#   - IsUnsolvable::islands() and related functions


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::More tests => 2;

    use IsUnsolvable;
    use Board;
    use Move;

    use Data::Dumper;


my $board_2islands = Board::new_from_string(<<'EOF');
           XX <<  .  5
           XX ^^  .  .
            .  . XX XX
            5  .  .  .
EOF

my $board_1island = Board::new_from_string(<<'EOF');
           XX  .  .  5
           XX ^^  .  .
            .  . XX XX
            5  .  .  .
EOF


is(IsUnsolvable::_immobile_grid_toString(
    IsUnsolvable::_islands_calculate_immobile($board_2islands)), trim(<<'EOF'), 'immobile grid for 2islands');
            XX..
            XX..
            ..XX
            ....
EOF

is(IsUnsolvable::_immobile_grid_toString(
    IsUnsolvable::_islands_calculate_immobile($board_1island)), trim(<<'EOF'), 'immobile grid for 1islands');
            X...
            X...
            ..XX
            ....
EOF




sub trim { (my $a=shift) =~ s/^\s+|\s+$//mg; "$a\n" }
