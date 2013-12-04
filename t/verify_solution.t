#!/usr/bin/perl

# After a solution has been found, uses TreeTraversal::verify_solution() to verify it's a valid
# solution.
#
# This runs against all boards in the t/boards_auto/ directory, and can take a fair bit of time,
# depending on what boards are placed there.


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::More;

    use TreeTraversal;
    use Board;

    use Data::Dumper;

my $board_dir = "boards_auto/";
if ($ENV{HARNESS_ACTIVE}) {
    $board_dir = "t/$board_dir";
}

$ARGV{'--relax'} = 1;

my @files = glob("$board_dir/*");
foreach my $file (@files) {
    (my $display_file = $file) =~ s#^.*/##;
    my $board = Board::new_from_file($file);
    my $move_list = TreeTraversal::A_star($board);
    if (!defined($move_list)) {
        ok(0, $display_file);
        next;
    }
    ok(TreeTraversal::verify_solution($board, $move_list), $display_file);
}

done_testing(scalar(@files));
