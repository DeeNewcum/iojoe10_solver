#!/usr/bin/perl

    use strict;
    use warnings;

open (STDOUT, "| tee compare.log")
    or die;


my @boards = qw_cmnt(<<'EOF');
        #Multiplying-4
        #Multiplying-11
        #Multiplying-2
        #Multiplying-5
        #Multiplying-8

        Multiplying-12
        Inverting-12

        Inverting-4
        Simple-2

        Inverting-5
        Blocks-9

        Inverting-6
        Blocks-11
        Inverting-3
        Multiplying-16

        Multiplying-14
        Multiplying-7
        Multiplying-13
        Multiplying-6
EOF

# allow the cmdline to override the board list
@boards = @ARGV     if @ARGV;

foreach my $board (@boards) {
    print "======== $board ========\n";
    system "./compare_one.pl", $board;
}



# Like qw[...], but it allows comments (hash symbol).
sub qw_cmnt {local$_=shift;s/\s+#.*//gm;split}
