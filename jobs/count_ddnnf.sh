#!/usr/bin/env bash
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

TIMEOUT_SECONDS=600
CONTAINER_IMAGE="${CONTAINER_IMAGE:-ghcr.io/tubs-isf/pb-ddnnf-eval:main-amd64}"
CONTAINER_MODE="${CONTAINER_MODE:-apptainer}"

ddnnf_file=$1
output=$2

tmpdir=$(mktemp -d)

cp $ddnnf_file "${tmpdir}/in"

case "$CONTAINER_MODE" in
"apptainer")
  apptainer exec -B $tmpdir:/out "docker://$CONTAINER_IMAGE" ddnnife --input /out/in count > ${tmpdir}/out
  ;;
"podman")
  podman run -v $tmpdir:/out $CONTAINER_IMAGE timeout $TIMEOUT_SECONDS ddnnife --input /out/in --output /out/out count
  ;;
*)
  echo "Unknown CONTAINER_MODE!"
  exit 1
  ;;
esac

if [ "$SLURM_MODE" = "local" ] && [ $? -ne 124 ]; then
  echo "COMPLETED"
fi

if [ "$SLURM_MODE" = "local" ] && [ $? -eq 124 ]; then
  echo "TIMEOUT"
fi

mv ${tmpdir}/out $output
