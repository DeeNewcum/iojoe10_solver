#!/usr/bin/perl

# tests for:
#   - IsUnsolvable::islands() and related functions


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::More tests => 4;

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



sub trim { (my $a=shift) =~ s/^\s+|\s+$//mg; "$a\n" }
