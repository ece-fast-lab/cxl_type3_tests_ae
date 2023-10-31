# Test figure 3, 4
This document describe how to reproduce the result in figure 3, 4a and 4b.

Under `memo_ae/evaluation`

## Testing
### Figure 3
```
$ bash figure_3.sh
```

### Figure 4a
```
$ bash figure_4a.sh
```

### Figure 4b
```
$ bash figure_4b.sh
```

## Results
The result is placed under `memo_ae/results/figure_*/`

### Figure 3
Under `results/figure_3_mlc`, these nodes are used for the Intel MLC latency values.
* 0-0 for DDR5-L
* 0-1 for DDR5-R
* 0-2 for CXL-X

Under `results/figure_3_memo`, each row within a txt shows the block access latency value for `ld` `nt-ld` `st` `nt-st` from top to bottom, respectively.
* `block_lats_n0.txt` has for DDR5-L 
* `block_lats_n1.txt` has for DDR5-R
* `block_lats_n2.txt` has for CXL-X 

### Figure 4a
Under `results/figure_4a`
* `c0-31_m1.txt` has the MLC peak injectino throughput for DDR5-R
* `c0-31_m2.txt` has the MLC peak injectino throughput for CXL-X

### Figure 4b
Under `results/figure_4b`, each row within a txt shows the bandwdith for thread 2 * (nth row), i.e. 2-threads, 4-threads, ..., 32-threads. The \_op\* denotes the operation: 0 for `ld`, 1 for `nt-ld`, 2 for `st` and 3 for `nt-st`.
* `seq_bw_op*_core0_mem1.txt` has the bandwidth number for DDR5-R
* `seq_bw_op*_core0_mem2.txt` has the bandwidth number for CXL-X
