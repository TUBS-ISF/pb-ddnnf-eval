#!/usr/bin/env bash
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

opb_file=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

cp $opb_file "${tmpdir}/in"

case "$CONTAINER_MODE" in
"apptainer")
  apptainer exec -B $tmpdir:/out "docker://${CONTAINER_IMAGE}" time -f "%e" -o /out/time p2d /out/in -m ddnnf -o /out/out
  ;;
"podman")
  podman run -v $tmpdir:/out $CONTAINER_IMAGE time -f "%e" -o /out/time p2d /out/in -m ddnnf -o /out/out
  ;;
*)
  echo "Unknown CONTAINER_MODE!"
  exit 1
  ;;
esac

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile
