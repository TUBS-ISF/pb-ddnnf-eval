#!/bin/sh

input=$1
task=$2

output="/pfs/work9/workspace/scratch/ul_wqa66-pb"

files=$(find $input -type f)

for uvl in $files
do
  instance="${uvl#*/}"

  for i in `seq 1 3`
  do
    job_name="${task}-${instance}-${i}"
    outfile="${output}/${instance}.${task}.${i}.out"
    errfile="${output}/${instance}.${task}.${i}.err"
    timefile="${output}/${instance}.${task}.${i}.time"

    dimacs_output="${output}/${instance}.${i}.dimacs"
    opb_output="${output}/${instance}.${i}.opb"
    opb_pbcount_output="${output}/${instance}.${i}.opb.pbcount"

    case "$task" in
    "dimacs")
      sbatch --job-name $job_name --output $outfile --error $errfile convert_dimacs.sh $uvl $dimacs_output $timefile
      ;;
    "opb")
      sbatch --job-name $job_name --output $outfile --error $errfile convert_opb.sh $uvl $opb_output $timefile
      ;;
    "opb-pbcount")
      sbatch --job-name $job_name --output $outfile --error $errfile convert_pbcount.sh $opb_output $opb_pbcount_output $timefile
      ;;
    *)
      echo "Unknown task!"
      exit 1
      ;;
    esac

    sleep 0.25
  done
done
