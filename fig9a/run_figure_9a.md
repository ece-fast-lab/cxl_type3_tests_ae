# Test figure 9a
This document describe how to reproduce the result in figure 9a.

## Testing
Under the MERCI folder:
### Figure 9a
```
$ bash figure_9a.sh
```

## Results
The result is located within the `<YCSB path>/result/figure_*/`

### Figure 9a
* For each txt file, the name "X\_Y.txt" demotes top and bot memory tier percentage: top = DDR5, bot = CXL-A.
* For each row within the txt, first row runs the DLRM embedding reduction with 4 threads, second row runs at 8 thread, etc. The last row should correspond to running at 32 threads.
* Each number denotes the average inference latency (ms) after many iterations. To covert to the millioin inference / sec, here is the formula:

$$1/(Latency_{avg} * 10^{-3}) * 744841/1000000$$

Therefore, the throughput is inversly proportional to the average inference latency.
