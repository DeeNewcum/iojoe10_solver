#!/usr/bin/perl

# tests for:
#   - Move::apply()


    use strict;
    use warnings;

    BEGIN {-t and eval "use lib '..'"}

    use Test::Simple tests => 3;

    use Board;
    use Move;

    use Data::Dumper;


$b = new Board( width=>3, height=>3 );

$b->cells->[2] = [qw[   5 -11   3 ]];
$b->cells->[1] = [qw[ -11 -11   7 ]];
$b->cells->[0] = [qw[ -11 -11 -11 ]];

select STDERR;
$b->display();
select STDOUT;



my $m = new Move('c3<');

$m->apply( $b );
