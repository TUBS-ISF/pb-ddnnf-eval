#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --time=120
#SBATCH --partition=cpu
#SBATCH --mem=32gb

# output interpretation for runtimes:
#  non-zero: runtime
#  -1: timeout
#  -2: out of memory
#  -3: process error within time limit
#  -9: other error

# output interpretation for results:
#  non-zero: result
#  -4: input file does not exist
#  -9: other error

output="/pfs/work9/workspace/scratch/ul_wqa66-pb"

input=$1
csv=$2

tmp_csv=$(mktemp)

files=$(find $input -type f)

for uvl in $files
do
  instance="${uvl#*/}"

  printf $instance >> $tmp_csv

  for task in dimacs opb opb_pbcount d4 p2d pbcount
  do
    printf "," >> $tmp_csv

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
      outfile="${file_basename}.out"
      timefile="${file_basename}.time"

      time_run=$(./parse_job.sh $outfile $timefile)

      printf -- "${time_run}" >> $tmp_csv

      if [ $i -lt 3 ]
      then
        printf ";" >> $tmp_csv
      fi
    done

    case "$task" in
    "dimacs")
      size=-4

      if [ -f $dimacs_output ]
      then
        size=$(./size_dimacs.sh $dimacs_output)
      fi

      printf ",${size}" >> $tmp_csv
      ;;
    "opb")
      size=-4

      if [ -f $opb_output ]
      then
        size=$(./size_opb.sh $opb_output)
      fi

      printf ",${size}" >> $tmp_csv
      ;;
    "d4")
      count=-9
      maybe_count=""

      if [ -f $d4_count ]
      then
        maybe_count=$(<$d4_count)
      fi

      if [[ $maybe_count == +([[:digit:]]) ]]
      then
        count=$maybe_count
      fi

      if [ ! -f $dimacs_output ]
      then
        count=-4
      fi

      printf ",${count}" >> $tmp_csv
      ;;
    "p2d")
      count=-9
      maybe_count=""

      if [ -f $p2d_count ]
      then
        maybe_count=$(<$p2d_count)
      fi

      if [[ $maybe_count == +([[:digit:]]) ]]
      then
        count=$maybe_count
      fi

      if [ ! -f $opb_output ]
      then
        count=-4
      fi

      printf ",${count}" >> $tmp_csv
      ;;
    "pbcount")
      count=-9
      maybe_count=""

      pbcount_output="${output}/${instance}.pbcount.1.out"
      maybe_count=$(./count_pbcount.sh $pbcount_output)

      if [[ $maybe_count == +([[:digit:]]) ]]
      then
        count=$maybe_count
      fi

      if [ ! -f $opb_pbcount_output ]
      then
        count=-4
      fi

      printf ",${count}" >> $tmp_csv
      ;;
    esac
  done

  printf "\n" >> $tmp_csv
done

printf "instance,dimacs_time,dimacs_size,opb_time,opb_size,opb_pbcount_time,d4_time,d4_count,p2d_time,p2d_count,pbcount_time,pbcount_count\n" > $csv
sort < $tmp_csv >> $csv
