#!/usr/bin/perl

# generate a report that's very similar to pcs.sh, but it indicates whether each file has the
# shortest-solution: field filled in or not

    use strict;
    use warnings;

    use Data::Dumper;
    #use Devel::Comments;           # uncomment this during development to enable the ### debugging statements


# Pipe this script's output to less
open my $our_out, '|-', q[ less -p '\*.*']      or die;
select $our_out;


open my $pin, './pcs.sh|'       or die;
while (<$pin>) {
    chomp;
    my $line = $_;
    my $filename = (split ' ')[0];

    my $contents = slurp($filename);        # the file's contents

    my $has_shortest_field = ($contents =~ /shortest_solution:\s*(\S+)/);
    my $num_moves = $has_shortest_field ? "$1 moves" : "";

    if ($contents =~ /approx_solution:\s*(\S+)/) {
        $num_moves = "$1 moves";
    }

    printf "%s  %-30s  %10s\n",
            ($has_shortest_field ? "**" : "  "),
            $line,
            $num_moves;
}



# quickly read a whole file     (like File::Slurp or IO::All->slurp)
sub slurp {my$p=open(my$f,"$_[0]")or die$!;my@o=<$f>;close$f;waitpid($p,0);wantarray?@o:join("",@o)}
