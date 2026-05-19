#!/usr/bin/env bash
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

CONTAINER_IMAGE="${CONTAINER_IMAGE:-ghcr.io/tubs-isf/pb-ddnnf-eval:main-amd64}"
CONTAINER_MODE="${CONTAINER_MODE:-apptainer}"

opb_file=$1
timefile=$2

tmpdir=$(mktemp -d)

cp $opb_file "${tmpdir}/in"

case "$CONTAINER_MODE" in
"apptainer")
  apptainer exec -B $tmpdir:/out "docker://${CONTAINER_IMAGE}" time -f "%e" -o /out/time pbcount --cf /out/in
  ;;
"podman")
  podman run -v $tmpdir:/out $CONTAINER_IMAGE time -f "%e" -o /out/time pbcount --cf /out/in
  ;;
*)
  echo "Unknown CONTAINER_MODE!"
  exit 1
  ;;
esac

mv "${tmpdir}/time" $timefile
