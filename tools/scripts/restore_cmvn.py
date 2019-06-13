import sys
import argparse
import os
import multiprocessing

import tensorflow as tf
import numpy as np

def process_in_each_thread(line, apply_cmvn):

    cmvn = np.load(os.path.join(FLAGS.work_dir, FLAGS.bark_cmvn_file))
    max_num = np.loadtxt(os.path.join(FLAGS.work_dir, FLAGS.max_num_file))
    inputs_path = os.path.join(FLAGS.input_dir, line)
    #inputs = read_binary_file(inputs_path, FLAGS.input_dim)
    print(inputs_path)
    inputs = np.load(inputs_path)
    inputs = inputs / 4  * max_num
    inputs = inputs * cmvn["stddev_inputs"] + cmvn["mean_inputs"]
    inputs = np.array(inputs,dtype=np.float32)

    print("max= %s min=%s " %(inputs.max() , inputs.min()))
    fout = os.path.join(FLAGS.output_dir,'{}.f32'.format(line.split('.')[0]))
    inputs.tofile(fout)

def convert_to(apply_cmvn):
    file_name = os.listdir(FLAGS.input_dir)
    # pool = multiprocessing.Pool(FLAGS.num_threads)
    # workers = []
    for line in file_name:
        line = line.strip()
        print("Processing file %s " % line)
        process_in_each_thread(line, apply_cmvn)
        # workers.append(pool.apply_async(
        #    process_in_each_thread, (line, apply_cmvn)))
    # pool.close()
    # pool.join()

def main(unused_argv):
    convert_to(apply_cmvn=True)
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
        '--work_dir',
        type=str,
        default='./',
        help='work dir to save cmvn file '
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
        '--output_dim',
        type=int,
        default=20,
        help='The dimension of outputs.'
    )
    parser.add_argument(
        '--max_abs_value',
        type=int,
        default=4
    )
    parser.add_argument(
        '--bark_cmvn_file',
        type=str,
        default='bark_cmvn.npz'
    )
    parser.add_argument(
        '--max_num_file',
        type=str,
        default='max_num'
    )

    FLAGS, unparsed = parser.parse_known_args()
    os.makedirs(FLAGS.output_dir, exist_ok=True)
    tf.app.run(main=main, argv=[sys.argv[0]] + unparsed)

