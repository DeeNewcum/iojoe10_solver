#!/bin/sh

# Run the code-coverage report.

cover --delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove \
            t/move.t            \
            t/move_apply.t      \
            t/test_core.t       \
                    || exit
# For this particular report, I want to focus on the Test-Core functions.
#       (the minimal set of functions that are required to be able to verify the results of
#        solver*.t;  these functions must be as bulletproof as possible)
perl -x "$0"        # generate the .uncoverable file
cover                           \
    -select Move.pm             \
    -select Board.pm            \
    -select TreeTraversal.pm
xdg-open cover_db/coverage.html

exit




############################# generate the .uncoverable file #############################
#!perl

    # Unfortunately, I haven't been able to figure out how to make this work yet.
    # Devel::Cover's documentation regarding "uncoverable" is lacking.
    # So, for now, I just ignore the part of the report that is undesirable, when I'm manually
    # reviewing the report.

    use strict;
    use warnings;

    use lib '.';

    use Board;
    use Move;

    use Digest::MD5;
    use Data::Dumper;

open my $fout, '>', '.uncoverable'          or die $!;

my %subs_to_include = (
    'Board.pm' => [qw[
        has_won
    ]],
    'Move.pm' => [qw[
        apply
        _in_bounds
        _is_piece_movable
        _is_piece_combinable
        _combine_pieces
    ]],
    'TreeTraversal.pm' => [qw[
        verify_solution
    ]],
);

foreach my $file (keys %subs_to_include) {
    (my $package = $file) =~ s/\.pm$//;
    #(my $md5 = qx[md5sum $file])    =~ s/ .*//s;

    my %include = map {$_ => 1} $subs_to_include{$file};

    foreach my $sub (list_subs_in_package($package)) {
        next if $include{$sub};
        my $line = qx[grep -h '^ *sub $sub' $file];
        if (!$line) {
            #warn "uhoh -- $file -- $sub\n";
            #print Dumper $line;
        } else {
            my $md5 = Digest::MD5::md5_hex($line);
            print $fout "$file subroutine $md5 0 0 Don't want to include in this report\n";
        }
    }
}


sub list_subs_in_package {
    my $module = shift;
    no strict 'refs';
    return grep { defined &{"$module\::$_"} } keys %{"$module\::"}
}
