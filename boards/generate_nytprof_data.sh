#!/bin/bash

# Generate NYTProf data, allowing us to compare the performance between two different versions

BOARD=Inverting-6

rm -rf nytprof.old*
rm -rf nytprof.new*


######## "new" configuration ########
perl -d:NYTProf ../iojoe10 $BOARD
mv nytprof.out nytprof.new.out
nytprofhtml --file nytprof.new.out --out nytprof.new

######## "old" configuration ########
            # --compare-old is a special flag, that I use specifically when doing A/B testing,
            #                   to specify the alternate configuration I want to test with
perl -d:NYTProf ../iojoe10 $BOARD --compare-old
mv nytprof.out nytprof.old.out
nytprofhtml --file nytprof.old.out --out nytprof.old

xdg-open nytprof.new/index.html
xdg-open nytprof.old/index.html
