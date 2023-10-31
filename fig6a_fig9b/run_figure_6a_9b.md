# Test figure 6a, 9b
This document describe how to reproduce the result in figure 6a and 9b.

## Testing
Under the YCSB folder:
### Figure 6a
```
$ bash figure_6a.sh
```

### Figure 9b
```
$ bash figure_9b.sh
```

## Results
The result is located within the `<YCSB path>/result/figure_*/`

### Figure 6a
The following command will extract the p99 latency for each interleaving ratio:
```
$ grep -r "99th" ./figure_6a | grep "Run" | grep "READ" | sort -V 
```

### Figure 9b
The following command will extract the max throughput for each interleaving ratio:
```
$ grep -r "Throughput(ops/sec)" ./figure_9b | grep "Run" | sort -V
```
