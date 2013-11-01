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
    [0,1],      # 1 = up
    [1,0],      # 2 = right
    [0,-1],     # 3 = down
    [-1,0],     # 4 = left
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

# Move the pieces on the board to reflect the specified move.
#
# Returns true if it was a legal move, false if it was illegal.
sub apply {
    my $self = shift;
    my ($board) = @_;

    return 0 if (!_in_bounds($board, $self->x, $self->y));

    my $cell = $board->{cells}[$self->y][$self->x];
    my @dir = @{ $direction[ $self->dir ] };
    
    if (abs($cell) > 10 && $cell % 100 != 0) {
        # This isn't a movable cell.  This isn't a legal move.
        return 0;
    }

    my @just_before_collision = ($self->x, $self->y);
    my @just_after_collision  = ($self->x, $self->y);

    do {
        @just_before_collision = @just_after_collision;
        $just_after_collision[0] += $dir[0];
        $just_after_collision[1] += $dir[1];
    } while (_in_bounds($board, @just_after_collision)
            && $board->{cells}[$just_after_collision[0]][$just_after_collision[1]] == -11);

    # LEFTOFF -- continue from here...  figure out what to do now that we hit something
}

    # returns true/false, indicating if the point lies inside the board
    sub _in_bounds {
        my ($board, $x, $y) = @_;
        return ($x >=0 && $x < $board->width
                && $y >=0 && $y < $board->height);
    }


1;
