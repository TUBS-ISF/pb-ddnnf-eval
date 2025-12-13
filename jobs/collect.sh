#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --time=120
#SBATCH --partition=cpu
#SBATCH --mem=32gb

output="/pfs/work9/workspace/scratch/ul_wqa66-pb"

input=$1
csv=$2

printf "instance,dimacs_time,opb_time,opb_pbcount_time,d4_time,d4_count,p2d_time,p2d_count,pbcount_time,pbcount_count\n" > $csv

files=$(find $input -type f)

for uvl in $files
do
  instance="${uvl#*/}"

  printf $instance >> $csv

  for task in dimacs opb opb_pbcount d4 p2d pbcount
  do
    printf "," >> $csv

    dimacs_output="${output}/${instance}.dimacs"
    opb_output="${output}/${instance}.opb"
    opb_pbcount_output="${output}/${instance}.opb_pbcount"
    d4_output="${output}/${instance}.nnf_d4"
    p2d_output="${output}/${instance}.nnf_p2d"
    d4_count="${output}/${instance}.count_d4"
    p2d_count="${output}/${instance}.count_p2d"
    pbcount_count="${output}/${instance}.count_pbcount"

    for i in `seq 1 3`
    do
      file_basename=${output}/${instance}.${task}.${i}
      timefile="${file_basename}.time"
      time_run=-1
      maybe_time=""

      if [ -f $timefile ]
      then
        maybe_time=$(<$timefile)
      fi

      if [[ $maybe_time == *([[:digit:]]).+([[:digit:]]) ]]
      then
        time_run=$maybe_time
      fi

      printf -- "${time_run}" >> $csv

      if [ $i -lt 3 ]
      then
        printf ";" >> $csv
      fi
    done

    case "$task" in
    "d4")
      count=-1
      maybe_count=""

      if [ -f $d4_count ]
      then
        maybe_count=$(<$d4_count)
      fi

      if [[ $maybe_count == +([[:digit:]]) ]]
      then
        count=$maybe_count
      fi

      printf ",${count}" >> $csv
      ;;
    "p2d")
      count=-1
      maybe_count=""

      if [ -f $p2d_count ]
      then
        maybe_count=$(<$p2d_count)
      fi

      if [[ $maybe_count == +([[:digit:]]) ]]
      then
        count=$maybe_count
      fi

      printf ",${count}" >> $csv
      ;;
    "pbcount")
      count=-1
      maybe_count=""

      pbcount_output="${output}/${instance}.pbcount.1.out"
      maybe_count=$(./count_pbcount.sh $pbcount_output)

      if [[ $maybe_count == +([[:digit:]]) ]]
      then
        count=$maybe_count
      fi

      printf ",${count}" >> $csv
      ;;
    esac
  done

  printf "\n" >> $csv
done
