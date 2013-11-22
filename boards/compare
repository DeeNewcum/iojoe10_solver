#!/usr/bin/perl

# Compare the performance of IDDFS and A*

    use strict;
    use warnings;

my $board = shift
    or die "Specify a board to compare.\n";

my @lines;

@lines = qx[ ./$board ];
summarize_output('A*',  \@lines);

@lines = qx[ ./$board --iddfs ];
summarize_output('IDDFS',  \@lines);


sub summarize_output {
    my ($title, $lines) = @_;
    my $summary = $lines->[-1];
    $summary =~ s/^\s{10}//;
    chomp $summary;
    printf "%-20s %s\n",
        $title,
        $summary;
}
