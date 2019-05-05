import os
import numpy as np
import sys

def replace(feats_dir, out_dir):
    file_list = os.listdir(feats_dir)
    for files in file_list:
        print('processing file %s' % files)
        files.strip()
        ffeats = os.path.join(feats_dir, files)
        ffeats_out = os.path.join(out_dir, files)
        feats = np.fromfile(ffeats,dtype=np.float32).reshape(-1,55)
        frame_nums = feats.shape[0]
        feats_out = np.zeros((frame_nums, 20),dtype=np.float32)
        feats_out[:frame_nums, 0:18] = feats[:frame_nums, 0:18]
        feats_out[: frame_nums, 18:20 ] = feats[:frame_nums,36:38]
        ffout = open(ffeats_out,'wb')
        feats_out.tofile(ffout)
        ffout.close()

def main():
    feats_dir = sys.argv[1]
    out_dir = sys.argv[2]
    os.makedirs(out_dir,exist_ok=True)
    replace(feats_dir, out_dir)

if __name__=='__main__':
    if len(sys.argv) != 3:
        print("Usage: python 55to20.py feats_55  out_dir")
        exit(0)
    main()
    print("done!")
