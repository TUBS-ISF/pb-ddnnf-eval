#!/bin/sh
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

image="ghcr.io/uulm-janbaudisch/opb2pbcount:main-amd64"

input=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

apptainer exec -B $tmpdir:/out docker://$image time -f "%e" -o /out/time opb2pbcount $input /out/out

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile
