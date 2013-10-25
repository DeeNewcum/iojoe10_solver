package Move;

    # Represents a single move to be made to a board.


    use strict;
    use warnings;

    use Moose;


has 'x', is => 'ro';
has 'y', is => 'ro';
has 'dir', is => 'ro';      # directions are 1=up, 2=right, 3=down, 4=left  (ie. CSS order)

1;
