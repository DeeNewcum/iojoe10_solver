package Board;

    use strict;
    use warnings;

    use Moo;
    use Storable;

    use Data::Dumper;


has 'width', is => 'ro';
has 'height', is => 'ro';
has 'cells', is => 'rw';
    # $self->cells  is a list-of-list structure.
    #       $self->cells->[$y][$x]
    #       (0,0) is at the bottom-left corner
    # Each cell contains a number:
    #       -11          empty space
    #       10          wall
    #       1 to 9      movable block
    #       -1 to -9    moveable block
    #       100, 200, 300, 400
    #                   a single-directional wall, that can move in the indicated direction
    #                   (100=up, 200=right, 300=down, 400=left)
    #       500         left/right moveable wall
    #       600         up/down moveable wall
    #       700         any direction moveable wall
    #
    #       800         invert      "+-"
    #
    #       52 to 59    x2, x3, x4, ... x9


# Variables needed for_the A* search algorithm
has 'f', is => 'rw';        # g + h -- our estimate of the total distance from the start node to the end node, travelling through this node
has 'g', is => 'rw';        # distance from start node to this node
has 'h', is => 'rw';        # our guess of how far we are from the end node
has 'came_from', is => 'rw';   # Breadcrumbs that allow us to trace our way to the beginning, once we found the end.
has 'came_from_move', is => 'rw';       # What move was made to get us from the predecessor?


sub BUILD {
    my $self = shift;

    if (!defined($self->{cells})) {
        $self->cells(
                [ map {
                        [ map
                              { -11 }
                              1..$self->width() ]
                      } 1..$self->height() ]
        );
    }
}


# load a board from a text file
sub new_from_file {
    my ($filename) = @_;

    -e $filename or die "$filename doesn't exist\n";

    open my $fh, '<', $filename     or die "error opening $filename -- $!\n";
    my @lines = <$fh>;
    close $fh;

    return new_from_string(  join("", @lines) );
}


my %from_string = (
    'xx'        =>  10,         # wall
    'x'         =>  10,         # wall
    '+-'        => 800,         # invert
    '.'         => -11,         # space / empty cell
    '^^'        => 100,         # slider -- up
    '>>'        => 200,         # slider -- right
    'vv'        => 300,         # slider -- down
    '<<'        => 400,         # slider -- left
    '<>'        => 500,         # slider -- left/right
    '^v'        => 600,         # slider -- up/down
    'rk'        => 700,         # slider -- all around      (RK = rook)
);
sub new_from_string {
    my ($string) = @_;

    my @lines = split /[\n\r]/, $string;
    @lines = map { s/#.*//; chomp; $_ } @lines;     # remove comments (and newlines)
    @lines = grep { /\S/ } @lines;                  # remove blank lines

    my ($height, $width);
    $height = scalar(@lines);
    $width = scalar(split ' ', $lines[0]);

    my $board = new Board(width => $width, height => $height);

    for (my $y=0; $y<$height; $y++) {
        my @cells = split ' ', $lines[$height - 1 - $y];
        for (my $x=0; $x<@cells; $x++) {
            if (exists $from_string{lc($cells[$x])}) {
                $cells[$x] = $from_string{lc($cells[$x])};
            } elsif ($cells[$x] =~ /^x([2-9])$/i) {         # multiplication
                $cells[$x] = 50 + $1;
            } elsif ($cells[$x] =~ /^-?[0-9]+$/) {          # numerical block
                $cells[$x] = int $cells[$x];
            } else {
                die "Unreconized token:   $cells[$x]\n";
            }
        }
        scalar(@cells) == $width
            or die "ERROR on row " . ($y + 1) . " -- Every row must have the same width\n";
        $board->{cells}[$y] = \@cells;
    }

    return $board;
}


sub clone {
    my $self = shift;
    return new Board(
        width  => $self->{width},
        height => $self->{height},
        cells  => Storable::dclone( $self->cells ),
    );
}


# returns true/false, whether the current position is a winning position
sub has_won {
    my $self = shift;

    for (my $y=0; $y<$self->height; $y++) {
        for (my $x=0; $x<$self->width; $x++) {
            if ($self->{cells}[$y][$x] != 0
                && abs($self->{cells}[$y][$x]) < 10)
            {
                return 0;
            }
        }
    }
    return 1;
}


our %to_fingerprint = (
    -11 => ' ',

      0 => '0',
      1 => '1',
      2 => '2',
      3 => '3',
      4 => '4',
      5 => '5',
      6 => '6',
      7 => '7',
      8 => '8',
      9 => '9',

     -1 => 'A',
     -2 => 'B',
     -3 => 'C',
     -4 => 'D',
     -5 => 'E',
     -6 => 'F',
     -7 => 'G',
     -8 => 'H',
     -9 => 'I',

     10 => 'X',

    100 => '^',
    200 => '>',
    300 => 'v',
    400 => '<',
    500 => '-',     # left/right
    600 => '|',     # up/down
    700 => '+',     # all four directions

    800 => '/',     # invert

    52 => 'u',
    53 => 'w',
    54 => 'y',
    55 => 'z',
    56 => 'U',
    57 => 'W',
    58 => 'Y',
    59 => 'Z',
);
# Generate a fingerprint for this board.  This provides a quick way to compare boards to see if
# they're the same position.
sub fingerprint {
    my $self = shift;
    my $str = '';
    for (my $y=$self->height-1; $y>=0; $y--) {
        for (my $x=0; $x<$self->width; $x++) {
            $str .= $to_fingerprint{ $self->at($y, $x) };
        }
        $str .= "\n";
    }
    return $str;
}


# Returns the value at a specific cell.
sub at {
    my $self = shift;
    my ($y, $x) = @_;

    return $self->{cells}[$y][$x];
}


# display the board
# (assumes the user has a 256-color capable terminal)
#       http://is.gd/256cols
sub display {
    my $self = shift;

    # prepare the output to accept UTF8 characters
    binmode STDOUT, ':utf8';
    binmode STDERR, ':utf8';

    # The "1" moveable tile is a distinctive color.  As is every other.
    # What color is it?
    # Each line contains:
    #   1. bg color for use with positive numbers, it should have good contrast with a white foreground
    #   2. fg color for use with negative numbers, it should have good contrast with a white background
    my @number_color = (
        [0, 0],     # 0 = black on white
        [1, 1],     # 1 = red
        [202, 202], # 2 = orange
        [3, 3],    # 3 = yellow
        [34, 34],   # 4 = light green
        [28, 28],   # 5 = medium green
        [22, 22],   # 6 = dark green
        [63, 63],   # 7 = light blue
        [18, 18],   # 8 = dark blue
        [198, 198], # 9 = pink
    );
    my @arrows = (
        "",
        " \x{2191}",       # 100 -- up
        " \x{2192}",       # 200 -- right
        " \x{2193}",       # 300 -- down
        " \x{2190}",       # 400 -- left
        " \x{21d4}",       # 500 -- left/right
        " \x{21d5}",       # 600 -- up/down
        #"\x{21d4}\x{21d5}", # 700 -- all directions
        " \x{253c}",       # 700 -- all directions
    );

    binmode STDOUT, ":encoding(UTF-8)";     # we're going to be outputting UTF8 characters
    #_ansi_cursor_home();

    # We have a special mode, where if we're just passed one block, we ONLY display that,
    # nothing else, not even a newline.
    my $oneblock = ($self->height == 1 && $self->width == 1);

    for (my $y=$self->height-1; $y>=0; $y--) {
        printf "%2d ", $y+1     unless $oneblock;
        for (my $x=0; $x<$self->width; $x++) {
            my $cell = $self->cells->[$y][$x];
            if (abs($cell) <= 9) {                                              # numerical block
                if ($cell > 0) {
                    _bg_color( $number_color[$cell][0] );
                    _fg_color( 15 );     # white foreground
                } else {
                    _fg_color( $number_color[abs($cell)][1] );
                    print "\e[107m";    # white background
                }
                printf "%2s", $cell;
            } elsif ($cell == 10) {                                             # wall
                _fg_color( 240 );       # dark gray
                _bg_color( 237 );       # dark gray
                print " X";
            } elsif ($cell == -11) {                                            # space
                _bg_color( 233 );       # black background
                print "  ";
            } elsif ($cell % 100 == 0 && $cell >= 100 && $cell <= 700) {        # sliding blocks
                print "\e[37m";         # white foreground
                _bg_color( 240 );        # medium gray
                print $arrows[$cell / 100];
            } elsif ($cell == 800) {                                            # invert
                _fg_color( 240 );       # medium gray
                _bg_color( 15 );       # white
                print "+-";
            } elsif ($cell >= 52 && $cell <= 59) {
                _bg_color( 34 );        # green
                _fg_color( 15 );        # white
                print "x" . int($cell - 50);
            }
        }
        print "\e[0m";
        #print "\n";
        _ansi_newline()     unless $oneblock;
    }
    if (!$oneblock) {
        #_ansi_newline();
        print "   ";
        for (my $x=0; $x<$self->width; $x++) {
            print " ", chr(ord("a") + $x);
        }
        _ansi_newline();
    }

    #print "\n\n";
    #_ansi_newline();
    #_ansi_newline();
    #_ansi_erase_below();
}

# This is terribly inefficient, but we don't use it that much.
sub display_one_piece {
    my ($piece) = @_;
    my $board = new Board(width => 1, height => 1);
    $board->{cells}[0][0] = $piece;
    $board->display();
}

    sub _fg_color {
        my $color = shift;
        print "\e[38;5;${color}m";
    }
    sub _bg_color {
        my $color = shift;
        print "\e[48;5;${color}m";
    }
    
    # clear the line, at the same time we're doing a newline
    sub _ansi_newline {
        print "\n\e[K";
    }
    sub _ansi_cursor_home {
        print "\e[1;1H";
        print "\e[K";
    }
    # After we've reached the last row, move down one line, and call this.  It will erase the rest
    # of the screen.
    sub _ansi_erase_below {
        print "\e[J";
    }

1;
