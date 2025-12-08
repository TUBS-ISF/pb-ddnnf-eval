#!/bin/sh
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

image="ghcr.io/uulm-janbaudisch/pb-ddnnf-eval:cluster-amd64"

uvl_file=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

apptainer exec -B $tmpdir:/out docker://$image time -f "%e" -o /out/time converter $uvl_file /out/out dimacs

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile
