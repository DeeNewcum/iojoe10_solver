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

1;
