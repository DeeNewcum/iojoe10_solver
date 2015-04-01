#!/bin/sh

# In some cases, the "shortest_solution:" field was generated using something other than
# --yardstick.  Or it was generated using an older (known buggy) --yardstick.
#
# TODO:  If the field was generated with something other than --yardstick  (eg. --relax=1),
#        then it should be changed to approx_solution:, to indicate that it isn't known 100%
#        correct.
#
# We want to make sure this field is only used when we have accurate up-to-date data, so that when
#           ./verify_solution.t --long
# is run, that it generates correct outputthat it generates correct output

grep -i ^shortest_solution: * | sort -n -k 2 | perl -ple 's/^([^:]*):/sprintf "%-25s", $1/e'
