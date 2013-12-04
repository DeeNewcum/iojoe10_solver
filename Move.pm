package Move;

    # Represents a single move to be made to a board.


    use strict;
    use warnings;

    use Moo;

    use Data::Dumper;


has 'x', is => 'ro';
has 'y', is => 'ro';
has 'dir', is => 'ro';      # directions are 1=up, 2=right, 3=down, 4=left  (ie. CSS order)

my %dir_chars = qw(
        1  ^
        2  >
        3  v
        4  <
);
our %dir_chars_inverse = reverse %dir_chars;
our @direction = (
    [0,0],
    [1,0],      # 1 = up
    [0,1],      # 2 = right
    [-1,0],     # 3 = down
    [0,-1],     # 4 = left
);
our %sliding_blocks = (      # which direction can sliding blocks go?
    100 => [1],         # up only
    200 => [2],         # right only
    300 => [3],         # down only
    400 => [4],         # left only
    500 => [2,4],       # left/right
    600 => [1,3],       # up/down
    700 => [1,2,3,4],   # any direction
);


around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if (@_ == 1 && ref($_[0]) eq '' && $_[0] =~ /^([a-z])(\d+)([<>v^])$/i) {
        # initialize from a string
        my $x = ord(lc($1)) - ord("a");
        my $y = $2 - 1;     # internal is zero-based;  chess notation is one-based
        my $dir = $dir_chars_inverse{$3};
        return $class->$orig(x => $x, y => $y, dir => $dir);
    } else {
        return $class->$orig(@_);
    }
};


sub movelist_from_string {
    my ($string) = @_;
    my @move_list = split ' ', $string;
    return map { new Move($_) } @move_list;
}


sub toString {
    my $self = shift;

    return sprintf "%s%d%s",
            chr($self->x + ord("a")),
            $self->y + 1,
            $dir_chars{$self->dir};
}


    sub _is_piece_movable {
        my ($cell) = @_;
        return 1 if ($cell % 100 == 0 && $cell >= 100 && $cell <= 700);     # sliding blocks
        return 1 if (abs($cell) <= 9);          # numerical blocks
        return 0;
    }

    # Can this piece combine with others?
    sub _is_piece_combinable {
        my ($cell) = @_;
        return 1 if (abs($cell) <= 9);                  # numerical blocks
        return 1 if ($cell >= 49 && $cell <= 59);       # multiplication
        return 0;
    }

    # Can this piece be left uncombined, and you can still win?
    #           (assumption:  Only pass combinable pieces to this)
    # See the document "corner_cases.txt".
    sub _can_win_without_combining {
        my ($cell) = @_;
        return ($cell >= 49 && $cell <= 59);       # multiplication (or invert, which is the same thing)
    }

    # Returns undef if this was an illegal move.
    # Otherwise returns the combined value.
    sub _combine_pieces {
        my ($cell1, $cell2) = @_;

        # This should be an assert() that only gets called during development, since we should
        # never get called with pieces that aren't combinable.
        # However, this is in Test-Core, so I want to make 110% sure that it behaves correctly.
        if (!_is_piece_combinable($cell1) || !_is_piece_combinable($cell2)) {
            return undef;
        }
        
        if (!_is_piece_movable($cell2)) {
            if (!_is_piece_movable($cell1)) {
                # Both of these pieces are combinable.
                # However, neither is movable, so they couldn't have come into contact with each other.
                # (eg. two inverts, or two multiplies, or an invert and a multiply)
                return undef;       # error, can't be combined
            }

            # If one piece is unmovable, make sure it's $cell1.  This reduces the number of
            # if-statements we have to do below.
            my $temp = $cell2;
            $cell2 = $cell1;
            $cell1 = $temp;
        }

        my $combined;
        if ($cell1 >= 49 && $cell1 <= 59) {     # multiply
            $combined = ($cell1 - 50) * $cell2;
        } else {
            $combined = $cell1 + $cell2;
        }

        if ($combined == -10) {
            $combined = 10;          # -10 and 10 are both walls, but for simplicity, we'll internally store them both as 10
        }

        return undef if ($combined > 10 || $combined < -10);

        return $combined;
    }


    sub apply_DEBUG { 0 }

# Move the pieces on the board to reflect the specified move.
#
# Modifies the existing board.  If you want to keep a copy of the board before the move was made,
# make a copy of the board before you apply the move (using Board::clone()).
#
# Return value is true/false, indicating whether anything changed on the board.
# False means either an illegal move, or a legal move that resulted in no change.
#
# When a change was made, the return value is a listref of the coordinates that the piece stopped
# at.
sub apply {
    my $self = shift;
    my ($board) = @_;

    print "apply -- making move:  ", $self->toString, "\n"      if apply_DEBUG();

    return 0 if (!_in_bounds($board, $self->{y}, $self->{x}));

    my $cell = $board->at( $self->{y}, $self->{x} );
    my @dir = @{ $direction[ $self->{dir} ] };
    
    if (!_is_piece_movable($cell)) {
        return 0;       # This is an illegal move -- this isn't a movable cell.
    }
    if (exists $sliding_blocks{$cell}) {
        my %allowed_directions = map {$_ => 1} @{ $sliding_blocks{$cell} };
        if (! $allowed_directions{ $self->dir }) {
            return 0;       # This is an illegal move -- this sliding block can't slide that way.
        }
    }

    my @just_before_collision = ($self->{y}, $self->{x});
    my @just_after_collision  = ($self->{y}, $self->{x});

    while (1) {
        print "apply -- ", _pos(@just_after_collision), "\n"        if apply_DEBUG();
        @just_before_collision = @just_after_collision;
        $just_after_collision[0] += $dir[0];
        $just_after_collision[1] += $dir[1];
        if (! _in_bounds($board, @just_after_collision)) {
            print "apply -- out of bounds\n"    if apply_DEBUG();
            last;
        } elsif ($board->at(@just_after_collision) != -11) {
            print "apply -- collided with:  ", $board->at(@just_after_collision), "\n" if apply_DEBUG();
            last;
        }
    };

    print "apply -- \@just_after_colission: ", _pos(@just_after_collision), "\n"        if apply_DEBUG();
    print "apply -- \@just_before_colission: ", _pos(@just_before_collision), "\n"      if apply_DEBUG();

    # Is this a sliding block, or a numerical block?

    if (exists $sliding_blocks{$cell}) {

        # This is a sliding block.
        if ($just_before_collision[0] == $self->{y}
         && $just_before_collision[1] == $self->{x})
        {
            return 0;       # The block didn't end up moving.
        } else {
            $board->{cells}[ $self->{y} ][ $self->{x} ] = -11;
            $board->{cells}[ $just_before_collision[0] ][ $just_before_collision[1] ] = $cell;
            return \@just_before_collision;
        }
    }

    # Okay, this is a numerical block.

    my $hit_cell = $board->at( @just_after_collision );
    if (!_in_bounds($board, @just_after_collision) || !_is_piece_combinable($hit_cell)) {
        # We hit a numerical block, or the side of the board.
        if ( $just_before_collision[0] == $self->{y} && $just_before_collision[1] == $self->{x}) {
            return 0;       # The block didn't end up moving.
        }
        $board->{cells}[ $just_before_collision[0] ][ $just_before_collision[1] ] = $cell;
        $board->{cells}[ $self->{y} ][ $self->{x} ] = -11;

        return \@just_before_collision;
    } else {
        # We hit a block we can combine with.

        my $combined = _combine_pieces($cell, $hit_cell);

        if (!defined($combined)) {
            return 0;       # illegal move -- the pairing was > 10
        }

        $board->{cells}[ $just_after_collision[0] ][ $just_after_collision[1] ] = $combined;
        $board->{cells}[ $self->{y} ][ $self->{x} ] = -11;

        return \@just_after_collision;
    }
}

    # returns true/false, indicating if the point lies inside the board
    sub _in_bounds {
        my ($board, $y, $x) = @_;
        return ($x >=0 && $x < $board->{width}
                && $y >=0 && $y < $board->{height});
    }

    # gives the human-readable string representation of a (X, Y) position
    sub _pos {
        my @elem;
        if (@_ == 2) {
            @elem = @_;
        } elsif (@_ == 1 && ref($_[0]) eq 'ARRAY') {
            @elem = @{$_[0]};
        } else {
            die;
        }

        defined($elem[0])  or $elem[0] = 'undef';
        defined($elem[1])  or $elem[1] = 'undef';

        # Internally, positions are represented as @pos[y][x].  When printing, display them as
        # (x, y).
        return sprintf "(%s, %s)", $elem[1], $elem[0];      
    }


#__PACKAGE__->meta->make_immutable();       # useful in Moose -- http://stackoverflow.com/a/3166324/1042525

1;
