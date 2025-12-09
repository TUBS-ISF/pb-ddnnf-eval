#!/bin/sh
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

image="docker://ghcr.io/uulm-janbaudisch/opb2pbcount:main-amd64"

input=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

cp $input "${tmpdir}/in"

apptainer exec -B $tmpdir:/out $image time -f "%e" -o /out/time opb2pbcount --input /out/in --output /out/out

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile
