#!/bin/bash

./apply-vad --frame-len=0.025 --frame-shift=0.005 \
                         --energy-thresh=1.5e7 \
                         --sil-to-speech-trigger=-50 \
                         --speech-to-sil-trigger=50 \
                         264.wav 1.vad.wav
