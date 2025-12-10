#!/bin/sh
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

image="docker://ghcr.io/uulm-janbaudisch/p2d:nix-amd64"

opb_file=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

cp $opb_file "${tmpdir}/in"

apptainer exec -B $tmpdir:/out $image time -f "%e" -o /out/time p2d /out/in -m ddnnf -o /out/out

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile
