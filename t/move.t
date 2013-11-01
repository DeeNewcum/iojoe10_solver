    use strict;
    use warnings;

    use Test::Simple tests => 3;
    use Move;

    use Data::Dumper;

my $m = new Move('d3v');

ok( $m->x == 3   &&  $m->y == 2 );

ok( $m->dir == 3 );

ok( $m->toString() eq 'd3v' );
