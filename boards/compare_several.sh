#!/usr/bin/perl

    use strict;
    use warnings;

open (STDOUT, "| tee compare_several.log")
    or die;


my @boards = qw_cmnt(<<'EOF');
        easy.08pieces
        Tricky-11
        Inverting-4
        Simple-2
        easy.09pieces
        Inverting-5
EOF

foreach my $board (@boards) {
    print "======== $board ========\n";
    system "./compare", $board;
}



# Like qw[...], but it allows comments (hash symbol).
sub qw_cmnt {local$_=shift;s/\s+#.*//gm;split}
