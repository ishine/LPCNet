#!/bin/bash
# -*- coding: utf-8 -*-

######################################################################
#
# Copyright ASLP@NPU. All Rights Reserved
#
# Licensed under the Apache License, Veresion 2.0(the "License");
# You may not use the file except in compliance with the Licese.
# You may obtain a copy of the License at
#
#   http://www.apache.org/license/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author npujcong@gmail.com(congjian)
#
######################################################################

current_working_dir=$(pwd)
LPC_NET_dir=$(dirname $(dirname $current_working_dir))

corpus_dir=${current_working_dir}/data
config_dir=${corpus_dir}/config
train_dir=${corpus_dir}/train
test_dir=${corpus_dir}/test

exp_dir=$current_working_dir/exp

model=`ls $exp_dir/nnet | tail -n 1`

stage=$1

# train
if [ $stage -le 1 ]; then
  ./pyqueue_tts.pl --gpu 1 log_train python ${LPC_NET_dir}/src/train_lpcnet.py \
    $train_dir/features.f32 \
    $train_dir/data.u8
fi

# dump lpcnet
if [ $stage -le 2 ]; then
   cd $LPC_NET_dir \
    && CUDA_VISIBLE_DEVICES=1 python src/dump_lpcnet.py \
       $exp_dir/nnet/$model \
    && mv nnet_data.* src \
    && make \
    && cp lpcnet_demo $exp_dir \
    && cd $current_working_dir
fi

if [ $stage -le 3 ]; then
  [ ! -e $exp_dir/test ] && mkdir -p $exp_dir/test
  for x in $test_dir/*.f32
  do
     b=${x##*/}
     echo synthesising $b ....
     $exp_dir/lpcnet_demo -synthesis $x $exp_dir/test/$b.pcm
     sox -t raw -c 1 -e signed-integer -b 16 -r 16000 \
         $exp_dir/test/$b.pcm \
         $exp_dir/test/$b.wav
  done
fi
