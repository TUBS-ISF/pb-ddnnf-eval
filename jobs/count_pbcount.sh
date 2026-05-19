#!/usr/bin/env bash

pbcount_logfile=$1

grep -E "^s mc .*\..*$" $pbcount_logfile | cut -d " " -f 3 | cut -d "." -f 1
