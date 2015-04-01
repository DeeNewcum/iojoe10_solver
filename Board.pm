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
    #       49          invert      "+-"
    #
    #       52 to 59    x2, x3, x4, ... x9

has 'file_fields', is => 'ro';       # fields that are specified in the board file

# Variables needed for_the A* search algorithm
has 'f', is => 'rw';        # g + h -- our estimate of the total distance from the start node to the end node, travelling through this node
has 'g', is => 'rw';        # distance from start node to this node
has 'h', is => 'rw';        # our guess of how far we are from the end node
has 'came_from_moves', is => 'rw';       # What move was made to get us from the predecessor?


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

    my $obj = new_from_string(  join("", @lines) );

    $obj->{file_fields}{filename} = $filename;

    return $obj;
}


my %from_string = (
    'xx'        =>  10,         # wall
    'x'         =>  10,         # wall
    '+-'        =>  49,         # invert
    '.'         => -11,         # space / empty cell
    '^^'        => 100,         # slider -- up
    '>>'        => 200,         # slider -- right
    'vv'        => 300,         # slider -- down
    '<<'        => 400,         # slider -- left
    '<>'        => 500,         # slider -- left/right
    '^v'        => 600,         # slider -- up/down
    'rk'        => 700,         # slider -- all around      (RK = rook)
);
my %from_string_inverse = reverse %from_string;

sub _piece_from_string {
    my $piece = shift;
    if (exists $from_string{lc($piece)}) {
        return $from_string{lc($piece)};
    } elsif ($piece =~ /^x([2-9])$/i) {         # multiplication
        return 50 + $1;
    } elsif ($piece =~ /^-?[0-9]+$/) {          # numerical block
        return int $piece;
    } else {
        die "Unreconized token:   $piece\n";
    }
}
sub new_from_string {
    my ($string) = @_;

    my @lines = split /[\n\r]/, $string;
    @lines = map { s/#.*//; chomp; $_ } @lines;     # remove comments (and newlines)
    @lines = grep { /\S/ } @lines;                  # remove blank lines

    my $fields;
    ($fields, @lines) = _parse_fields(\@lines);

    my ($height, $width);
    $height = scalar(@lines);
    $width = scalar(split ' ', $lines[0]);

    my $board = new Board(width => $width, height => $height, file_fields => $fields);

    for (my $y=0; $y<$height; $y++) {
        my @cells = split ' ', $lines[$height - 1 - $y];
        for (my $x=0; $x<@cells; $x++) {
            $cells[$x] = _piece_from_string($cells[$x]);
        }
        scalar(@cells) == $width
            or die "ERROR on row " . ($y + 1) . " -- Every row must have the same width\n";
        $board->{cells}[$y] = \@cells;
    }

    return $board;
}

    # parse SMTP-style header fields
    sub _parse_fields {
        my ($lines) = @_;
        my $re = '^\s*([a-zA-Z_][a-zA-Z0-9_]*): +(.*)';
        my @fields = grep /$re/o, @$lines;
        $lines = [ grep { ! /$re/o } @$lines ];
        my %fields;
        foreach my $f (@fields) {
            $f =~ /$re/o;
            my ($var, $val) = ($1, $2);
            $val =~ s/\s+$//s;
            $fields{$var} = $val;
        }
        return \%fields, @$lines;
    }


sub clone {
    my $self = shift;
    return new Board(
        width  => $self->{width},
        height => $self->{height},
        cells  => Storable::dclone( $self->cells ),
        file_fields => $self->{file_fields},
        g => $self->{g},
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
    -11 => ' ',         # space / empty cell

      0 => '0',         # movable blocks with positive values
      1 => '1',         #       (is it possible to have a movable block with value "0"??)
      2 => '2',
      3 => '3',
      4 => '4',
      5 => '5',
      6 => '6',
      7 => '7',
      8 => '8',
      9 => '9',

     -1 => 'A',         # movable blocks with negative values
     -2 => 'B',
     -3 => 'C',
     -4 => 'D',
     -5 => 'E',
     -6 => 'F',
     -7 => 'G',
     -8 => 'H',
     -9 => 'I',

     10 => 'X',         # wall

    100 => '^',         # sliders
    200 => '>',
    300 => 'v',
    400 => '<',
    500 => '-',         # left/right
    600 => '|',         # up/down
    700 => '+',         # all four directions

    49 => '/',          # invert

    52 => 'u',          # movable block:  x2
    53 => 'w',          #                 x3
    54 => 'y',          #                 x4, etc
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
    for (my $y=$self->{height}-1; $y>=0; $y--) {
        for (my $x=0; $x<$self->{width}; $x++) {
            $str .= $to_fingerprint{  $self->{cells}[$y][$x]  };
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
            } elsif ($cell == 49) {                                            # invert
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


# Just like display_one_piece(), with two minor differences:
#       1) it returns the string, instead of printing it, and
#       2) it doesn't include any ANSI escape codes, it's black-n-white
sub piece_toString {
    my ($piece) = @_;
    if ($piece == 10 || $piece == -10) {        # wall
        return "XX";
    } elsif ($piece == -11) {                   # empty space
        return ".";
    } elsif ($piece > -10 && $piece < 10) {     # numerical slider
        return $piece;
    } elsif (exists $from_string_inverse{$piece}) {        # non-numerical slider
        return $from_string_inverse{$piece};
    } elsif ($piece == 49) {                    # invert
        return "+-";
    } elsif ($piece >= 52 && $piece <= 59) {    # multiply
        return "x" . int($piece - 50);
    }
    die "OOPS";
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
