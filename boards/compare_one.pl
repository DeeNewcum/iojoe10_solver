#!/usr/bin/perl

    use strict;
    use warnings;

my $board = shift
    or die "Specify a board to compare.\n";

my @lines;

@lines = qx[ ./$board ];
summarize_output('new',  \@lines);

@lines = qx[ ./$board --compare-old ];
summarize_output('old',  \@lines);


sub summarize_output {
    my ($title, $lines) = @_;
    #my $summary = $lines->[-2] . $lines->[-1];
    $lines->[-2] =~ s/^\s{10}//;
    #chomp $summary;
    #$summary =~ s/\n /\n                      /s;
    printf "%-20s %s",
        $title,
        $lines->[-2];
    1 && printf "%-20s %s",
        '',
        $lines->[-1];
}
