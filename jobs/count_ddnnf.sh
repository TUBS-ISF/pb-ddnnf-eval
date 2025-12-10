#!/bin/sh
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

image="docker://ghcr.io/softvare-group/ddnnife:0.10.0-amd64"

ddnnf_file=$1
output=$2

tmpdir=$(mktemp -d)

cp $ddnnf_file "${tmpdir}/in"

apptainer exec -B $tmpdir:/out $image ddnnife --input /out/in count > ${tmpdir}/out

mv ${tmpdir}/out $output
