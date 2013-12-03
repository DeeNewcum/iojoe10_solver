#!/usr/bin/perl

# The "Test Core" are the minimal set of functions that are required to be able to verify the
# results of solver*.t.  We want these functions to be *thoroughly* tested.
#
# (see docs/TestCore.txt)


# tests for:
#   - Move::_combine_pieces()
#   - Move::_is_piece_movable
#   - Board::has_won()
#   - TreeTraversal::verify_solution()


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::More tests => 20;

    use Board;
    use Move;
    use TreeTraversal;

    use Data::Dumper;

# don't hardcode the piece values
my $invert = Board::_piece_from_string(  '+-'  );
my $rook   = Board::_piece_from_string(  'RK'  );
my $wall   = Board::_piece_from_string(  'XX'  );
my $times2 = Board::_piece_from_string(  'x2'  );

is( Move::_combine_pieces( $invert, $invert ), undef,   "two inverts can't combine");
is( Move::_combine_pieces( 2, $times2 ), 4,             "two times two");
is( Move::_combine_pieces( 5, $times2 ), $wall,         "2 * 5 = wall");
is( Move::_combine_pieces( -5, $times2 ), $wall,        "2 * -5 = 10  (not -10)");
is( Move::_combine_pieces(  6, $times2 ), undef,        "when combined, it's more than 10");
is( Move::_combine_pieces( -6, $times2 ), undef,        "when combined, it's less than -10");
is( Move::_combine_pieces( $wall, 5), undef,            "can't combine with a wall, part 1");
is( Move::_combine_pieces( 5, $wall), undef,            "can't combine with a wall, part 2");

ok( ! Move::_is_piece_movable( $invert ),               "invert doesn't move");
ok(   Move::_is_piece_movable( $rook ),                 "rook does move");

ok( ! Move::_is_piece_combinable( $wall ),              "wall isn't combinable");


ok( ! Board::new_from_string(<<'EOF')->has_won,         "hasn't won yet, part1");
                7 .
                . 3
EOF

ok( Board::new_from_string(<<'EOF')->has_won,           "has won, part1");
                . .
                . X
EOF

ok( Board::new_from_string(<<'EOF')->has_won,           "has won, only zero remaining");
                . .
                . 0
EOF

ok( Board::new_from_string(<<'EOF')->has_won,           "has won, only multiply remaining");
                . .
                . x2
EOF

ok( Board::new_from_string(<<'EOF')->has_won,           "has won, only invert remaining");
                . .
                . +-
EOF



################################################################################
################################################################################

my $board = Board::new_from_string(<<'EOF');
        6 7 4
        . . .
        . 3 .

        shortest_solution: 2
EOF


ok( !TreeTraversal::verify_solution($board, [ Move::movelist_from_string( 'b3v' ) ]),
            "solution doesn't finish on a winning board");

ok( !TreeTraversal::verify_solution($board, [ Move::movelist_from_string( 'a3>' ) ]),
            "solution has an illegal move");

ok( !TreeTraversal::verify_solution($board, [ Move::movelist_from_string( 'b1> b3v b1> c3<' ) ]),
            "solution is too long");

ok( TreeTraversal::verify_solution($board, [ Move::movelist_from_string( 'b3v c3<' ) ]),
            "verify_solution() works");

1;
