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

# process the cmdline args (eg. if  `prove :: --long`  is run, then $ARGV{'--long'} will show up here)
%::ARGV = getopt_simple();

my $base_dir = $ENV{HARNESS_ACTIVE} ? "./" : "../";     # allow the script to be run directly, or from 'prove'

$ARGV{'--relax'} = 1;       # make sure that TreeTraversal::heuristic() looks for a rigorously-optimal solution

my @files = glob "$base_dir/t/boards_auto/*";

# prove :: --long       means that you want to run the FULL suite of tests, and you're fine with
#                       it taking a while to complete
if ($ARGV{'--long'}) {
    # if this is run with:          prove :: --long
    # then verify all boards in the boards/ directory that have a shortest_solution: field
    @files = grep {-f} glob "$base_dir/boards/*";
    @files = grep {slurp($_) =~ /^shortest_solution:/m} @files;
}
print STDERR "\n";
foreach my $file (@files) {
    (my $display_file = $file) =~ s#^.*/##;
    print STDERR "\r    $display_file                                 \n";
    my $board = Board::new_from_file($file);
    my $move_list = TreeTraversal::A_star($board);
    if (!defined($move_list)) {
        ok(0, $display_file);
        next;
    }
    ok(TreeTraversal::verify_solution($board, $move_list), $display_file);
}

done_testing(scalar(@files));



# Simplified version of getopt -- allows ANY dash-argument, each can take an optional parameter.
#       Example command line:       -a -b --flag1 --flag2 value2 --flag3 value3
sub getopt_simple {my($p,$_p)=1;map{($_p,$p)=($p,1);if(/^-/){($_,$_p)}else{$p=$_;()}}reverse@ARGV}

# quickly read a whole file                 (like File::Slurp or IO::All->slurp)
sub slurp {my$p=open(my$f,"$_[0]")or die$!;my@o=<$f>;close$f;waitpid($p,0);wantarray?@o:join("",@o)}
