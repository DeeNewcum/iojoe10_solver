package Board;

    use strict;
    use warnings;

    use Moose;


has 'width', is => 'ro';
has 'height', is => 'ro';
has 'cells', is => 'rw';
    # $self->cells  is a list-of-list structure.
    #       $self->cells->[$y][$x]
    #       (0,0) is at the top-left corner
    # Each cell contains a number:
    #       0           empty space
    #       10          wall
    #       1 to 9      movable block
    #       -1 to -9    moveable block
    #       100, 200, 300, 400
    #                   a single-directional wall, that can move in the indicated direction
    #                   (100=up, 200=right, 300=down, 400=left)
    #       500         left/right moveable wall
    #       600         up/down moveable wall
    #       700         any direction moveable wall


sub BUILD {
    my $self = shift;

    $self->cells(
            [ map {
                    [ map
                          { 0 }
                          1..$self->width() ]
                  } 1..$self->height() ]
    );
}

# display the board
# (assumes the user has a 256-color capable terminal)
#       http://is.gd/256cols
sub display {
    my $self = shift;

    # The "1" moveable tile is a distinctive color.  As is every other.
    # What color is it?
    #   (for each line, there's two colors:  the first is the foreground color version, with good
    #   contrast with a white foreground...   the second is the background color version, with good
    #   contrast with a white background)
    my @number_color = (
        [],         # nada
        [1, 1],     # 1 = red
        [172, 172], # 2 = orange
        [3, 94],    # 3 = yellow
        [40, 40],   # 4 = light green
        [28, 28],   # 5 = medium green
        [22, 22],   # 6 = dark green
        [63, 63],   # 7 = light blue
        [18, 18],   # 8 = dark blue
        [198, 198], # 9 = pink
    );
    my @arrows = (
        "",
        " \x{2191}",       # 100
        " \x{2192}",       # 200
        " \x{2193}",       # 300
        " \x{2190}",       # 400
    );

    binmode STDOUT, ":encoding(UTF-8)";     # we're going to be outputting UTF8 characters
    _ansi_cursor_home();

    for (my $y=0; $y<$self->height; $y++) {
        for (my $x=0; $x<$self->width; $x++) {
            my $cell = $self->cells->[$y][$x];
            if (abs($cell) >= 1 && abs($cell) <= 9) {
                if ($cell > 0) {
                    _bg_color( $number_color[$cell][0] );
                    print "\e[37m";     # white foreground
                } else {
                    _fg_color( $number_color[abs($cell)][1] );
                    print "\e[107m";    # white background
                }
                printf "%2s", $cell;
            } elsif ($cell == 10) {
                print "\e[90m";         # gray foreground
                _bg_color( 237 );        # dark gray

                print " X";
            } elsif ($cell % 100 == 0 && $cell >= 100 && $cell <= 400) {
                print "\e[37m";         # white foreground
                _bg_color( 240 );        # medium gray
                print $arrows[$cell / 100];
            }
        }
        print "\e[0m";
        #print "\n";
        _ansi_newline();
    }
    #print "\n\n";
    #_ansi_newline();
    #_ansi_newline();
    _ansi_erase_below();
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
