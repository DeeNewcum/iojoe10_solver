#!/bin/bash

# Generate NYTProf data, allowing us to compare the performance between two different versions

BOARD=Inverting-6

rm -rf nytprof.old*
rm -rf nytprof.new*



# Put the nytprof.out file in a ramdisk -- it's ~1gb, and all that activity can reduce the lifetime of my SSD.
OUTFILE_LOCATION=/tmp/nytprof.out       # Where will the nytprof.out file be located?  (it can be quite large)
# There's a ramdisk already at /run/user/$USER/, however it's awfully small.  I've got 8gb RAM, let's use it!
mount | grep /media/nytprof.ramdisk >/dev/null
if [ $? != 0 ]; then
    [ -d /media/nytprof.ramdisk/ ] || sudo mkdir -p /media/nytprof.ramdisk/
    sudo mount -t tmpfs -o size=2048M tmpfs /media/nytprof.ramdisk/
fi
mount | grep /media/nytprof.ramdisk >/dev/null
if [ $? = 0 ]; then
    OUTFILE_LOCATION=/media/nytprof.ramdisk/nytprof.out
else
    echo UNABLE TO STORE nytprof.out ON SSD
fi
export NYTPROF="file=$OUTFILE_LOCATION"



######## "new" configuration ########
perl -d:NYTProf ../iojoe10 $BOARD
nytprofhtml --file $OUTFILE_LOCATION --out nytprof.new
rm $OUTFILE_LOCATION          # this thing is ~1GB!

######## "old" configuration ########
            # --compare-old is a special flag, that I use specifically when doing A/B testing,
            #                   to specify the alternate configuration I want to test with
perl -d:NYTProf ../iojoe10 $BOARD --compare-old
nytprofhtml --file $OUTFILE_LOCATION --out nytprof.old
rm $OUTFILE_LOCATION          # this thing is ~1GB!


xdg-open nytprof.new/index.html
xdg-open nytprof.old/index.html
