#!/bin/bash

input=$1
csv=$2

sbatch --job-name collect --output collect.out --error collect.err collect.sh $input $csv
