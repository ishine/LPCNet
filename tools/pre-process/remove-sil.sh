#!/bin/bash

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
# Date 2019/01/24 17:07:20

# trim silence and remain 100ms(20 frames) at the begining and the end of the audio

input_dir=$1
output_dir=$2

for x in input_dir/*.wav
do
  x=${x##*/}
  ${pro_dir}/pre-process/vad/apply-vad \
      --frame-len=0.025 \
      --frame-shift=0.005 \
      --energy-thresh=1.5e7 \
      --sil-to-speech-trigger=-20 \
      --speech-to-sil-trigger=20 \
      ${input_dir}/$x \
      ${output_dir}/$x
done
