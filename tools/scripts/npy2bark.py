import os
import sys
import numpy as np


def bark2npy(feats_dir, out_dir):
    file_list = os.listdir(feats_dir)
    for filename in file_list:
        filename = filename.strip()
        print('Processing file %s ' % filename)
        ffeats = os.path.join(feats_dir,filename)
        fout   = os.path.join(out_dir, '{}.f32'.format(filename.split('.')[0]))

        feats = np.load(ffeats)
        feats = feats.reshape(-1,20)

        feats.tofile(fout)

def main():
    npy_dir = sys.argv[1]
    out_dir = sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    bark2npy(npy_dir, out_dir)
    print('done!')


if __name__=='__main__':
    main()

