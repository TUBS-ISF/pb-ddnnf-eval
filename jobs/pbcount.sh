#!/bin/sh
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

image="docker://ghcr.io/uulm-janbaudisch/pbcount:nix-amd64"

opb_file=$1
timefile=$2

tmpdir=$(mktemp -d)

cp $opb_file "${tmpdir}/in"

apptainer exec -B $tmpdir:/out $image time -f "%e" -o /out/time pbcount --cf /out/in

mv "${tmpdir}/time" $timefile
