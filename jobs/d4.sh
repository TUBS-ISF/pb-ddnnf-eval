#!/bin/sh
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

image="docker://ghcr.io/softvare-group/d4v2:2.3.2-amd64"

dimacs_file=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

cp $dimacs_file "${tmpdir}/in"

apptainer exec -B $tmpdir:/out $image time -f "%e" -o /out/time d4 --method ddnnf-compiler --input /out/in --dump-ddnnf /out/out

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile
