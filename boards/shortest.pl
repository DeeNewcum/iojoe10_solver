#!/usr/bin/perl

# generate a report that's very similar to pcs.sh, but it indicates whether each file has the
# shortest-solution: field filled in or not

    use strict;
    use warnings;

    use lib '..';

    use Board;
    use IsUnsolvable;

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

    my $board = Board::new_from_file($filename);

    my @pcs = IsUnsolvable::_list_pieces($board);
    my @pcs_mults = grep {$_ >= 49} @pcs;

    my $has_shortest_field = exists $board->{file_fields}{shortest_solution};
    my $num_moves = $has_shortest_field ? "$board->{file_fields}{shortest_solution} moves" : "";

    if (!$has_shortest_field && exists $board->{file_fields}{approx_solution}) {
        $board->{file_fields}{approx_solution} =~ s/\s+$//s;
        $num_moves = "$board->{file_fields}{approx_solution} moves";
    }

    printf "%s  %-32s%4s    %10s\n",
            ($has_shortest_field ? "**" : "  "),
            $line,
            (@pcs_mults ? "[" . scalar(@pcs_mults) . "]" : ""),
            $num_moves;
}



# quickly read a whole file     (like File::Slurp or IO::All->slurp)
sub slurp {my$p=open(my$f,"$_[0]")or die$!;my@o=<$f>;close$f;waitpid($p,0);wantarray?@o:join("",@o)}
