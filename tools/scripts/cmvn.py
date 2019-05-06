import sys
import argparse
import os
import multiprocessing
import tensorflow as tf
import numpy as np
from utils import read_binary_file


def calculate_cmvn():
    print("Caluculating mean and var of input")
    filename = os.listdir(FLAGS.input_dir)
    inputs_frame_count = 0
    for line in filename:
        line = line.strip()
        print("Reading file %s" % line)
        inputs_path = os.path.join(FLAGS.input_dir, line)
        inputs = read_binary_file(inputs_path, FLAGS.input_dim)

        if inputs_frame_count == 0:
            ex_inputs = np.sum(inputs, axis=0)
            ex2_inputs = np.sum(inputs**2, axis=0)
        else:
            ex_inputs += np.sum(inputs, axis=0)
            ex2_inputs += np.sum(inputs**2, axis=0)
        inputs_frame_count += len(inputs)

    mean_inputs = ex_inputs / inputs_frame_count
    stddev_inputs = np.sqrt(ex2_inputs / inputs_frame_count - mean_inputs**2)
    stddev_inputs [stddev_inputs < 1e-20] = 1e-20
    np.savez(FLAGS.bark_cmvn_file,
            mean_inputs=mean_inputs,
            stddev_inputs=stddev_inputs)

def norm():
    file_name = os.listdir(FLAGS.output_dir)
    max_num = 0
    for line in file_name:
        line = line.strip()
        inputs_path = os.path.join(FLAGS.output_dir, line)
        inputs = np.load(inputs_path)
        if max_num < inputs.max():
            max_num = inputs.max()
        if max_num < abs( inputs.min() ):
            max_num = abs (inputs.min())

    for line in file_name:
        line = line.strip()
        inputs_path = os.path.join(FLAGS.output_dir, line)
        inputs = np.load(inputs_path)
        outputs = (inputs *  FLAGS.max_abs_value) / max_num
        output_path = os.path.join(FLAGS.output_dir2, line)
        np.save(output_path, outputs, allow_pickle=False)
    f_max_num = open(FLAGS.max_num_file, 'w')
    f_max_num.write(str(max_num))

def process_in_each_thread(line, apply_cmvn):
    inputs_path = os.path.join(FLAGS.input_dir, line)
    inputs = read_binary_file(inputs_path, FLAGS.input_dim)
    cmvn = np.load(FLAGS.bark_cmvn_file + ".npz")
    inputs = (inputs - cmvn["mean_inputs"]) / cmvn["stddev_inputs"]
    inputs[inputs > 100 ] = 100
    inputs[inputs < -100] = -100
    fout = os.path.join(FLAGS.output_dir,'{}.npy'.format(line.split('.')[0]))
    np.save(fout, inputs, allow_pickle=False)

def convert_to(apply_cmvn):
    file_name = os.listdir(FLAGS.input_dir)
    pool = multiprocessing.Pool(FLAGS.num_threads)
    workers = []
    for line in file_name:
        # process_in_each_thread(line, apply_cmvn)
        line = line.strip()
        workers.append(pool.apply_async(
            process_in_each_thread, (line, apply_cmvn)))
    pool.close()
    pool.join()

def main(unused_argv):
    calculate_cmvn()
    convert_to(apply_cmvn=True)
    norm()
    print("done")

if __name__== '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--num_threads',
        type = int,
        default='4',
        help='The number of threads to run'
    )
    parser.add_argument(
        '--input_dir',
        type=str,
        default='bark',
        help='The input dir to compute cmvn'
    )
    parser.add_argument(
        '--input_dim',
        type=int,
        default=20,
        help='The dimension of inputs.'
    )
    parser.add_argument(
        '--output_dir',
        type=str,
        default='bark_cmvn',
        help='The output dir after cmvn'
    )
    parser.add_argument(
        '--output_dir2',
        type=str,
        default='bark_cmvn_norm',
        help='The output dir after cmvn and norm'
    )
    parser.add_argument(
        '--max_abs_value',
        type=int,
        default=4
    )
    parser.add_argument(
        '--bark_cmvn_file',
        type=str,
        default="bark_cmvn"
    )
    parser.add_argument(
        '--max_num_file',
        type=str,
        default="max_num"
    )

    FLAGS, unparsed = parser.parse_known_args()
    os.makedirs(FLAGS.output_dir, exist_ok=True)
    os.makedirs(FLAGS.output_dir2, exist_ok=True)
    tf.app.run(main=main, argv=[sys.argv[0]] + unparsed)
