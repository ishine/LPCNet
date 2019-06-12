#!/bin/bash
# Copyright 2018 ASLP@NPU.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: npuichigo@gmail.com (zhangyuchao)
# Modified by npujcong@gmail.com (congjian)

current_working_dir=$(pwd)
LPC_NET_dir=$(dirname $(dirname $current_working_dir))

wav_dir=${current_working_dir}/raw/audio

corpus_dir=${current_working_dir}/data

pcm_dir=${corpus_dir}/pcm
config_dir=${corpus_dir}/config
train_dir=${corpus_dir}/train
test_dir=${corpus_dir}/test

num_test_case=5
train_scp=$config_dir/train.scp
test_scp=$config_dir/test.scp

stage=-1

set -euo pipefail

[ ! -e $pcm_dir ] && mkdir -p $pcm_dir
[ ! -e $config_dir ] && mkdir -p $config_dir
[ ! -e $train_dir ] && mkdir -p $train_dir
[ ! -e $test_dir ] && mkdir -p $test_dir

# trim silence and remain 100ms(20 frames) at the begining and the end of the audio

if [ $stage -le -1 ];then
  for x in ${wav_dir}/*.wav
  do
    x=${x##*/}
    ${LPC_NET_dir}/tools/pre-process/vad/apply-vad \
        --frame-len=0.025 \
        --frame-shift=0.005 \
        --energy-thresh=1.5e7 \
        --sil-to-speech-trigger=-20 \
        --speech-to-sil-trigger=20 \
        ${wav_dir}/$x \
        ${wav_dir}/tmp-$x
    mv ${wav_dir}/tmp-$x ${wav_dir}/$x
  done
fi

if [ $stage -le 0 ];then
  for x in $wav_dir/*.wav
  do
    b=${x##*/}
    echo Extracting pcm data from $b
    sox $wav_dir/$b -r 16000 -b 16 -c 1 -e signed-integer -t raw - > $pcm_dir/${b%.*}.s16
  done
fi

if [ $stage -le 1 ];then
  find $pcm_dir -name '*.s16' |shuf  >  $config_dir/all.scp
  awk -v count=${num_test_case} '{if (NR > count) { print $0 > "'$train_scp'"; } else { print $0 > "'$test_scp'"; }}' $config_dir/all.scp
fi

if [ $stage -le 2 ];then
  echo Preparing training data with dump_data
  $LPC_NET_dir/dump_data -train $train_scp $train_dir/features.f32 $train_dir/data.u8
fi

echo Preparing training data done

if [ $stage -le 3 ];then
  echo Preparing test data with dump_data
  for line in $(cat $test_scp); do
    basename=${line##*/}
    filename=${basename%.*}
    echo $line > /tmp/single_line_test_scp
    $LPC_NET_dir/dump_data -test /tmp/single_line_test_scp $test_dir/
  done

  rm /tmp/single_line_test_scp
fi
