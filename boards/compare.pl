#!/usr/bin/perl

    use strict;
    use warnings;

open (STDOUT, "| tee compare.log")
    or die;


my @boards = qw_cmnt(<<'EOF');
        Inverting-4
        Simple-2

        Inverting-5
        Blocks-9

        Inverting-6
        Blocks-11
        Inverting-3
        Multiplying-16
EOF

foreach my $board (@boards) {
    print "======== $board ========\n";
    system "./compare_one.pl", $board;
}



# Like qw[...], but it allows comments (hash symbol).
sub qw_cmnt {local$_=shift;s/\s+#.*//gm;split}
