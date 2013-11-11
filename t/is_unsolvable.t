#!/usr/bin/perl

# tests for:
#   - IsUnsolvable::*


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 4;

    use IsUnsolvable;
    use Board;
    use Move;

    use Data::Dumper;

ok(ok_unsolv( noclipping_mark1 => <<'EOF', 1));
          5   .   4 
          .   .   7 
          .   .   5 
EOF

ok(ok_unsolv( noclipping_mark1 => <<'EOF', 0));
          5   .   3 
          .   .   7 
          .   .   5 
EOF

ok(ok_unsolv( noclipping_mark1 => <<'EOF', 1));
          5   .   3 
          .   5   9 
          5   .   5 
EOF

ok(ok_unsolv( noclipping_mark1 => <<'EOF', 0));
          5   .   1 
          .   5   9 
          .   .   5 
EOF


sub ok_unsolv {
    my ($algo, $board_str, $expected_result) = @_;

    my $board = Board::new_from_string($board_str);
    my $actual_result = eval "IsUnsolvable::$algo(\$board)";
    die $@      if $@;

    my $ret = (~~$actual_result == ~~$expected_result);
    if (!$ret && -t STDOUT) {
        print "==== failed $algo ====\n";
        print "     expected: $expected_result      got: $actual_result\n";
        $board->display;
    }
    return $ret;
}


