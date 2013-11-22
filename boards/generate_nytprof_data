#!/bin/bash

# Generate NYTProf data, comparing the A* algorithm to IDDFS

rm -rf nytprof.iddfs*
rm -rf nytprof.astar*

perl -d:NYTProf ../iojoe10 easy.09pieces
mv nytprof.out nytprof.astar.out
nytprofhtml --file nytprof.astar.out --out nytprof.astar

perl -d:NYTProf ../iojoe10 easy.09pieces --iddfs
mv nytprof.out nytprof.iddfs.out
nytprofhtml --file nytprof.iddfs.out --out nytprof.iddfs

xdg-open nytprof.astar/index.html
xdg-open nytprof.iddfs/index.html
