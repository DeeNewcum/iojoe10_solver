package Move;

    # Represents a single move to be made to a board.


    use strict;
    use warnings;

    use Moose;

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
my %dir_chars_inverse = reverse %dir_chars;
my @direction = (
    [0,0],
    [1,0],      # 1 = up
    [0,1],      # 2 = right
    [-1,0],     # 3 = down
    [0,-1],     # 4 = left
);
my %sliding_blocks = (      # which direction can sliding blocks go?
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

sub toString {
    my $self = shift;

    return sprintf "%s%d%s",
            chr($self->x + ord("a")),
            $self->y + 1,
            $dir_chars{$self->dir};
}

    sub apply_DEBUG { 0 }

# Move the pieces on the board to reflect the specified move.
#
# Modifies the existing board.  If you want to keep a copy of the board before the move was made,
# make a copy of the board before you apply the move (using Board::clone()).
#
# Returns a boolean indicating whether anything changed on the board.
# False means either an illegal move, or a legal move that resulted in no real change.
sub apply {
    my $self = shift;
    my ($board) = @_;

    print "apply -- making move:  ", $self->toString, "\n"      if apply_DEBUG();

    return 0 if (!_in_bounds($board, $self->y, $self->x));

    my $cell = $board->at( $self->y, $self->x );
    my @dir = @{ $direction[ $self->dir ] };
    
    if (abs($cell) > 9 && $cell % 100 != 0) {
        return 0;       # This is an illegal move -- this isn't a movable cell.
    }
    if (exists $sliding_blocks{$cell}) {
        my %allowed_directions = map {$_ => 1} @{ $sliding_blocks{$cell} };
        if (! $allowed_directions{ $self->dir }) {
            return 0;       # This is an illegal move -- this sliding block can't slide that way.
        }
    }

    my @just_before_collision = ($self->y, $self->x);
    my @just_after_collision  = ($self->y, $self->x);

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

    # Is this a numerical block?

    if (exists $sliding_blocks{$cell}) {
        # No, just a sliding block.
        if ($just_before_collision[0] == $self->y
         && $just_before_collision[1] == $self->x)
        {
            return 0;       # The block didn't end up moving.
        } else {
            $board->{cells}[ $self->y ][ $self->x ] = -11;
            $board->{cells}[ $just_before_collision[0] ][ $just_before_collision[1] ] = $cell;
            return 1;
        }
    }

    # Okay, this is a numerical block.

    # Did we hit a non-numerical block, or the side of the board?
    my $hit_cell = $board->at( @just_after_collision );
    if (!_in_bounds($board, @just_after_collision) || abs($hit_cell) > 9) {
        if ( $just_before_collision[0] == $self->y && $just_before_collision[1] == $self->x) {
            return 0;       # The block didn't end up moving.
        }
        $board->{cells}[ $just_before_collision[0] ][ $just_before_collision[1] ] = $cell;
        $board->{cells}[ $self->y ][ $self->x ] = -11;
    } else {
        # We hit a numerical block.
        if ($hit_cell + $cell > 10) {
            return 0;       # illegal move
        }
        $board->{cells}[ $just_after_collision[0] ][ $just_after_collision[1] ] = $cell + $hit_cell;
        $board->{cells}[ $self->y ][ $self->x ] = -11;
    }

    return 1;
}

    # returns true/false, indicating if the point lies inside the board
    sub _in_bounds {
        my ($board, $y, $x) = @_;
        return ($x >=0 && $x < $board->width
                && $y >=0 && $y < $board->height);
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


1;
