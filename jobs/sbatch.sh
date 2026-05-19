#!/usr/bin/env bash

job=$2
outfile=$4
errfile=$6
script=$7
args=${@:8}

case "$SLURM_MODE" in
"slurm")
  sbatch $@
  ;;
"local")
  echo "Running $job ..."
  ./$script $args > $outfile 2> $errfile
  ;;
*)
  echo "Unknown SLURM_MODE!"
  exit 1
  ;;
esac
