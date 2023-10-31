# Configuration for figure 13
This document describe how to configurate a machine to reproduce the result in figure 13

## Hardware
These are the hardware used to produce the figures:

| Hardware | Description |
| -------- | ----------- |
| CPU | 2x Intel Xeon 6430 CPU |
| DRAM | DDR5 4800 MT/s (see below for DIMM configurations)|
| CXL devices | PCIe attached CXL devices |

### BIOS configuration
* Hyperthreading -- disabled
* Sub-NUMA clustering -- **enabled**
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
    Sub-NUMA node 0,1,2,3 --- Sub-NUMA node 4,5,6,7
        |
        |
        |
     CXL device (node 8)
```

## Software
### SPEC2017
Please follow the SPEC2017 setup to build the benchmark

### Redis / DLRM
Please follow configuration 6a / 9a / 9b to setup Redis, YCSB, and ASPLOS'21 MERCI - DLRM.

### Patched Linux Kernel:
We applied the N:M interleaving [patch](https://lore.kernel.org/linux-mm/YqD0%2FtzFwXvJ1gK6@cmpxchg.org/T/) to a Linux Kernel 5.19. We make the following modification to allow a more fine-grain tuning of the memory ratio:
  + The patch added a tunable parameter (numa\_tier\_interleave) in `vm_table` in `kernel/sysctl.c`
  + In our case, we use two parameters to control the top and bot ratio independetly
    * `numa_tier_interleave_top` for top tier
    * `numa_tier_interleave_bot` for bot tier
  + The rest of the patch is applied without any modification
  + We later found out that this step is not needed ;) --  `sudo sysctl -w numa_tier_interleave="<top> <bot>"` can achieve the same effect.


### System configuration
The `util_scripts/config_all.sh` is executed before each test within the testing scripts.

It does the following configurations:
* Lock CPU frequency 
* Disable frequency boosting
* Disable hyperthreading in software
* Disable NUMA balancing
* Stop `numad` if it exists
