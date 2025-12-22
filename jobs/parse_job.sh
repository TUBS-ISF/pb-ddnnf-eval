#!/bin/sh

# output interpretation:
#  non-zero: runtime
#  -1: timeout
#  -2: out of memory
#  -3: process error within time limit
#  -9: other error

outfile=$1
timefile=$2

state=$(tail -n8 < $outfile | head -n1 | cut -d " " -f 2)

time_run=-3
maybe_time=""

if [ -f $timefile ]
then
  maybe_time=$(head -n1 < $timefile)
fi

if [[ $maybe_time == *([[:digit:]]).+([[:digit:]]) ]]
then
  time_run=$maybe_time
fi

case "$state" in
"COMPLETED")
  echo $time_run
  exit 0
  ;;
"TIMEOUT")
  echo "-1"
  exit 0
  ;;
"OUT_OF_MEMORY")
  echo "-2"
  exit 0
  ;;
*)
  echo "-9"
  exit 0
  ;;
esac
