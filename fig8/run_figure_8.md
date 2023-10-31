# Test figure 8
This document describe how to reproduce the result in figure 8.

## Testing
Under the FIO folder:
### Figure 8 
```
$ bash figure_8.sh
```

## Results
The result is store in `<PATH to FIO>/result/fig_8/*`

The files are named as `<node>_<file_cache_size>_<block_size>.txt`

Here is a simple command to gather the result for a FIO block size of 4KB
```
$ grep -r "99.00th" ./result/fig_8/ | grep "\/4k" |  sort -V
```
