# Caption

This folder contains the configurations to reproduce figure 13 of the paper.

[Configuration](./config_figure_13.md)

Since this requires setting up SPEC2017, Redis, and ASPLOS'21 MERCI, it would be hard to have a unify setup.

Instead of providing our testing scripts, we elaborate the high-level testing procedure here:

Figure 13 is entirely tested on the syncrhnous tuning mode: tunning is applied whenever the bash script ended.

## Procedure
### 100:0
Use `numactl --membind` to bind all memory to local DRAM.

### 50:50
Use `numactl --interleave` to interleave 50% of memory to CXL and 50% of memory to local DRAM.

### Caption
1. Embed the targeted benchmark into a shell script
2. `python3 caption -s <path to script>`
    1. This will tune the targeted application at the end of each execution.
    2. By default, Caption tune for 7 interations. You may change this in the `caption.py` 
