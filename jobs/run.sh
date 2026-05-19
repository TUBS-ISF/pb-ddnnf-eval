#!/usr/bin/env bash

input=$1
output=$2
task=$3

files=$(find $input -type f)

command -v squeue > /dev/null 2>&1 && SLURM_MODE="${SLURM_MODE:-slurm}"
SLURM_MODE="${SLURM_MODE:-local}"
export SLURM_MODE

command -v apptainer > /dev/null 2>&1 && CONTAINER_MODE="${CONTAINER_MODE:-apptainer}"
command -v podman > /dev/null 2>&1 && CONTAINER_MODE="${CONTAINER_MODE:-podman}"
export CONTAINER_MODE

export CONTAINER_IMAGE="${CONTAINER_IMAGE:-ghcr.io/tubs-isf/pb-ddnnf-eval:main-amd64}"

echo "Using ${SLURM_MODE} system and ${CONTAINER_MODE} with image ${CONTAINER_IMAGE}."

for uvl in $files
do
  if [ "$SLURM_MODE" = "slurm" ]; then
    current_jobs=$(squeue | wc -l)
    while [ $current_jobs -ge 500 ]
    do
        echo "job limit reached, sleeping ..."
        sleep 60
        current_jobs=$(squeue | wc -l)
    done
  fi

  instance="${uvl#*/}"

  dimacs_output="${output}/${instance}.dimacs"
  opb_output="${output}/${instance}.opb"
  opb_pbcount_output="${output}/${instance}.opb_pbcount"
  d4_output="${output}/${instance}.nnf_d4"
  p2d_output="${output}/${instance}.nnf_p2d"
  d4_count="${output}/${instance}.count_d4"
  p2d_count="${output}/${instance}.count_p2d"

  mkdir -p $(dirname $dimacs_output)

  for i in `seq 1 3`
  do
    job_name="${task}-${instance}-${i}"

    file_basename=${output}/${instance}.${task}.${i}
    outfile="${file_basename}.out"
    errfile="${file_basename}.err"
    timefile="${file_basename}.time"

    case "$task" in
    "dimacs")
      ./sbatch.sh --job-name $job_name --output $outfile --error $errfile convert_dimacs.sh $uvl $dimacs_output $timefile
      ;;
    "opb")
      ./sbatch.sh --job-name $job_name --output $outfile --error $errfile convert_opb.sh $uvl $opb_output $timefile
      ;;
    "opb_pbcount")
      ./sbatch.sh --job-name $job_name --output $outfile --error $errfile convert_pbcount.sh $opb_output $opb_pbcount_output $timefile
      ;;
    "d4")
      ./sbatch.sh --job-name $job_name --output $outfile --error $errfile d4.sh $dimacs_output $d4_output $timefile
      ;;
    "p2d")
      ./sbatch.sh --job-name $job_name --output $outfile --error $errfile p2d.sh $opb_output $p2d_output $timefile
      ;;
    "pbcount")
      ./sbatch.sh --job-name $job_name --output $outfile --error $errfile pbcount.sh $opb_pbcount_output $timefile
      ;;
    "count_d4")
      continue
      ;;
    "count_p2d")
      continue
      ;;
    "collect")
      continue
      ;;
    *)
      echo "Unknown task!"
      exit 1
      ;;
    esac

    sleep 0.25
  done

  file_basename=${output}/${instance}.${task}
  outfile="${file_basename}.out"
  errfile="${file_basename}.err"
  timefile="${file_basename}.time"

  case "$task" in
  "count_d4")
    ./sbatch.sh --job-name $job_name --output $outfile --error $errfile count_ddnnf.sh $d4_output $d4_count
    ;;
  "count_p2d")
    ./sbatch.sh --job-name $job_name --output $outfile --error $errfile count_ddnnf.sh $p2d_output $p2d_count
    ;;
  "collect")
    ./sbatch.sh --job-name collect --output "${output}/collect.out" --error "${output}/collect.err" collect.sh $input $output "${output}/results.csv"
    ;;
  esac
done
