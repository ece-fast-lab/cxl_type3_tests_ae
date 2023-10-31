# Test figure 6b, 6c, 6d
This document describe how to reproduce the result in figure 6b, 6c, 6d

## Testing
Under the `socialNetwork/wrk2`:
### Figure 6b
```
$ bash fig_6b.sh
```

### Figure 6c
```
$ bash fig_6c.sh
```

### Figure 6d
```
$ bash fig_6d.sh
```

## Results
The result is placed under `fig_6*` folders.

To collect the latency value for each test, the following command will extract the raw value:
```
$ grep -r "99.000" ./fig_6b/ | sort -V 
```
This is an example command for collecting data in figure 6b.
