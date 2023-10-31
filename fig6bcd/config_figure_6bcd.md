# Configuration for figure 6b, 6c, and 6d
This document describe how to configurate a machine to reproduce the result in figure 6b, 6c, and 6d.

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
### DeathStarBench
Please follow the DeathStarBench(DSB) [repository](https://github.com/delimitrou/DeathStarBench) to setup the benchmark.

Please follow the steps in this [documentation](database_bind.pdf) on generating docker images that bind the memory to the CXL node.

The following steps is performed within the `socialNetwork` folder:
1. Place all the yml script (docker-compose-\*.sh) into the 

The following steps is performed within the `socialNetwork/wrk2` folder:
1. Place all the shell script (fig\_6i\*.sh) into this folder.

These scripts will run the social network framework in loop, and the generated docker images may take up many spaces. The command below will [clean the images](https://middleware.io/blog/docker-cleanup/). It's recommandated to execute this command before each testing.
```
$ docker volume prune
```

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
