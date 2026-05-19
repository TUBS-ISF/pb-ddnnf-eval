#!/usr/bin/env bash
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

ddnnf_file=$1
output=$2

tmpdir=$(mktemp -d)

cp $ddnnf_file "${tmpdir}/in"

case "$CONTAINER_MODE" in
"apptainer")
  apptainer exec -B $tmpdir:/out "docker://$CONTAINER_IMAGE" ddnnife --input /out/in count > ${tmpdir}/out
  ;;
"podman")
  podman run -v $tmpdir:/out $CONTAINER_IMAGE ddnnife --input /out/in --output /out/out count
  ;;
*)
  echo "Unknown CONTAINER_MODE!"
  exit 1
  ;;
esac

mv ${tmpdir}/out $output
