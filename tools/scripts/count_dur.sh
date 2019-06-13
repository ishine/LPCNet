#!/bin/bash
dir=$1
txt=$2
for x in ${dir}/*.wav
do
  b=${x##*/}
  echo $b `soxi ${dir}/$b 2>&1 | sed -n '6p' | cut -d ' ' -f 9 | cut -d ':' -f 3` >> $2
done
