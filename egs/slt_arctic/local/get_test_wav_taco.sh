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
# Author: npujcong@gmail.com (congjian)


stage=$1
name=$2 # name/out

current_working_dir=$(pwd)
LPC_NET_dir=$(dirname $(dirname $current_working_dir))
exp_dir=$current_working_dir/exp

work_dir=$exp_dir/$name

taco_out=$work_dir/out
taco_out_20=$work_dir/20
taco_out_55=$work_dir/55
wav_dir=$work_dir/wav

# dump lpcnet
if [ $stage -le 0 ]; then
   model=`ls $exp_dir/nnet | tail -n 1`
   cd $LPC_NET_dir \
    && CUDA_VISIBLE_DEVICES=0 python src/dump_lpcnet.py \
       $exp_dir/nnet/$model \
    && mv nnet_data.* src \
    && make \
    && cp lpcnet_demo $exp_dir \
    && cd $current_working_dir
fi


if [ $stage -le 1 ];then
    python $LPC_NET_dir/tools/scripts/restore_cmvn.py \
        --input_dir=$taco_out \
        --output_dir=$taco_out_20
    python $LPC_NET_dir/tools/scripts/20to55.py \
        $taco_out_20 \
        $taco_out_55
fi

if [ $stage -le 2 ]; then
  [ ! -e $wav_dir ] && mkdir -p $wav_dir
  for x in $taco_out_55/*.f32
  do
     b=${x##*/}
     echo synthesising $b ....
     $exp_dir/lpcnet_demo -synthesis $x $wav_dir/$b.pcm
     sox -t raw -c 1 -e signed-integer -b 16 -r 16000 \
         $wav_dir/$b.pcm \
         $wav_dir/$b.wav
  done
fi
