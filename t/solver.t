#!/usr/bin/perl

# System test -- Tests the solver as a whole.
#
# This also tests TreeTraversal.pm, which is difficult/impossible to unit-test on its own.


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 4;

    use TreeTraversal;
    use Board;

    use Data::Dumper;


ok(ok_solver(       "b1^ a1> c1^ b3v a3>",
<<'EOF'));
    # Vertical slider.
    # Same as t/boards/slider3.
#######################################
      3   .   .   .
     XX   .   .  XX
      7 600   .  XX
#######################################
EOF


ok(ok_solver(       "undef",
<<'EOF'));
    # Same as t/boards/unsolvable.
#######################################
      7   .
      .   2
#######################################
EOF


ok(ok_solver(       "a1> c1^ c3> f3v f1> j1^ j3>",
<<'EOF'));
    # A series of one-way gates that force the solution to be strictly made in a specific order.
    # Same as t/boards/auto_1.
#######################################
    X  .  .  .  .  1  .  X x9  .  .  2
    X  X  .  X  X  .  X  X  X  .  X  X
    2  .  .  X  .  .  .  .  .  5  .  X
#######################################
EOF



ok(ok_solver(       "a1> c1^ c3> f3v f1> j1^ j3>",
<<'EOF'));
    # A series of one-way gates that force the solution to be strictly made in a specific order.
    # Same as t/boards/auto_2.
#######################################
X  .  .  .  . x2  .  X x9  .  .  5                                                                   
X  X  .  X  X  .  X  X  X  .  X  X                                                                   
3  .  .  X  .  .  .  .  . -1  .  X 
#######################################
EOF






sub ok_solver {
    my ($expected_solution, $board_string) = @_;

    my $board = Board::new_from_string($board_string);
    my $got_solution = TreeTraversal::A_star($board);

    my $got_solution_string;
    if (!defined($got_solution)) {
        $got_solution_string = 'undef';
    } else {
        $got_solution_string = join(' ', map {$_->toString} @$got_solution);
    }

    my $ok = lc($got_solution_string) eq lc($expected_solution);
    if (!$ok) {
        print STDERR "\n",
                     "SOLVER ERROR     got solution:  $got_solution_string\n",
                     "            expected solution:  $expected_solution\n\n";
    }
    return $ok;
}
