# Configuration for figure 3, 4
This document describe how to configurate a machine to reproduce the result in figure 3, 4a and 4b.

## Hardware
These are the hardware used to produce the figures:

| Hardware | Description |
| -------- | ----------- |
| CPU | 2x Intel Xeon 6430 CPU |
| DRAM | DDR5 4800 MT/s (see below for DIMM configurations)|
| CXL devices | PCIe attached CXL devices |

### BIOS configuration
* Hyperthreading -- disabled
* Sub-NUMA clustering -- disabled
* CXL-Type3 legacy mode -- enabled (check with your CXL device vendor)

### DRAM population
```
- Socket 0
    - DIMM 1 <Inserted>
    - DIMM 2 <Inserted>
    ...
    - DIMM 7 <Inserted>
- Socket 1
    - DIMM 1 <Inserted>
    - DIMM 2 <Not used>
    ...
    - DIMM 7 <Not used>
```

### Inserting CXL device
```
    NUMA node 0 --- NUMA node 1
        |
        |
        |
     CXL device
```
In this case, all test will run with CPU cores on NUMA node 0 (`$CLOSEST_NODE`). 
* N0-N0 = NUMA local access
* N0-N1 = NUMA remote access
* N0-N2 = CXL access

## Software
Please download Intel MLC and place the binary in `memo_ae/app/mlc_linux/`

### System configuration
The `util_scripts/config_all.sh` is executed before each test within the testing scripts.

It does the following configurations:
* Lock CPU frequency 
* Disable frequency boosting
* Disable hyperthreading in software
* Disable NUMA balancing
* Stop `numad` if it exists

On Xeon 6430, the freqeuncy is locked to 2100MHz. The TSC freqeuncy on our machine is also 2100MHz. Please adjust the `util_scripts/lock_cpu_freq.sh` if this is tested on a different platform. The result may be significantly different if the frequency is not adjusted to the max frequency of the CPU.
