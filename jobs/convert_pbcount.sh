#!/usr/bin/env bash
#SBATCH --ntasks=1
#SBATCH --time=10
#SBATCH --partition=cpu
#SBATCH --mem=32gb

input=$1
output=$2
timefile=$3

tmpdir=$(mktemp -d)

cp $input "${tmpdir}/in"

case "$CONTAINER_MODE" in
"apptainer")
  apptainer exec -B $tmpdir:/out "docker://$CONTAINER_IMAGE" time -f "%e" -o /out/time opb2pbcount --input /out/in --output /out/out
  ;;
"podman")
  podman run -v $tmpdir:/out $CONTAINER_IMAGE time -f "%e" -o /out/time opb2pbcount --input /out/in --output /out/out
  ;;
*)
  echo "Unknown CONTAINER_MODE!"
  exit 1
  ;;
esac

mv "${tmpdir}/out" $output
mv "${tmpdir}/time" $timefile

rm -r $tmpdir
