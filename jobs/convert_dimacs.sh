#!/usr/bin/env bash
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

CONTAINER_IMAGE="${CONTAINER_IMAGE:-ghcr.io/tubs-isf/pb-ddnnf-eval:main-amd64}"
CONTAINER_MODE="${CONTAINER_MODE:-apptainer}"

uvl_file=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

case "$CONTAINER_MODE" in
"apptainer")
  apptainer exec -B $tmpdir:/out "docker://$CONTAINER_IMAGE" time -f "%e" -o /out/time converter $uvl_file /out/out dimacs
  ;;
"podman")
  podman run -v $tmpdir:/out -v $(realpath $uvl_file):/input $CONTAINER_IMAGE time -f "%e" -o /out/time converter /input /out/out dimacs
  ;;
*)
  echo "Unknown CONTAINER_MODE!"
  exit 1
  ;;
esac

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile
