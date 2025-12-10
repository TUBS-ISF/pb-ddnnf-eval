#!/bin/sh

input=$1
task=$2

output="/pfs/work9/workspace/scratch/ul_wqa66-pb"

files=$(find $input -type f)

for uvl in $files
do
  current_jobs=$(squeue | wc -l)

  while [ $current_jobs -ge 500 ]
  do
    echo "job limit reached, sleeping ..."
    sleep 60
    current_jobs=$(squeue | wc -l)
  done

  instance="${uvl#*/}"

  for i in `seq 1 3`
  do
    job_name="${task}-${instance}-${i}"

    file_basename=${output}/${instance}.${task}.${i}
    outfile="${file_basename}.out"
    errfile="${file_basename}.err"
    timefile="${file_basename}.time"

    dimacs_output="${output}/${instance}.dimacs"
    opb_output="${output}/${instance}.opb"
    opb_pbcount_output="${output}/${instance}.opb_pbcount"
    d4_output="${output}/${instance}.nnf_d4"
    p2d_output="${output}/${instance}.nnf_p2d"

    case "$task" in
    "dimacs")
      sbatch --job-name $job_name --output $outfile --error $errfile convert_dimacs.sh $uvl $dimacs_output $timefile
      ;;
    "opb")
      sbatch --job-name $job_name --output $outfile --error $errfile convert_opb.sh $uvl $opb_output $timefile
      ;;
    "opb_pbcount")
      sbatch --job-name $job_name --output $outfile --error $errfile convert_pbcount.sh $opb_output $opb_pbcount_output $timefile
      ;;
    "d4")
      sbatch --job-name $job_name --output $outfile --error $errfile d4.sh $dimacs_output $d4_output $timefile
      ;;
    "p2d")
      sbatch --job-name $job_name --output $outfile --error $errfile p2d.sh $opb_output $p2d_output $timefile
      ;;
    "pbcount")
      sbatch --job-name $job_name --output $outfile --error $errfile pbcount.sh $opb_pbcount_output $timefile
      ;;
    *)
      echo "Unknown task!"
      exit 1
      ;;
    esac

    sleep 0.25
  done
done
