#!/bin/bash

# Display the size of all boards, sorted by number of pieces.

grep -I [p]cs * 2>/dev/null | sort -n -k 3 | perl -F':#' -nale 'printf "%-15s %s\n", @F'


# to list boards that don't haven't properly listed their number of pieces, run this:
#       \ls -1 | perl -nle 'next if (-d || !-x || /\.sh$/); print unless qx[grep pcs $_]'
