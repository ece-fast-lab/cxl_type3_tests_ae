# Configuration for figure 8
This document describe how to configurate a machine to reproduce the result in figure 8.

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
### FIO
1 Please follow the procedure in the FIO repository to build the FIO benchmark
```
$ git clone https://github.com/axboe/fio.git
```
2. After setting up FIO, please place the `figure_8.sh` and `test_config` to the FIO directory.

3. Create a 50GB file called `123`
```
fallocate -l 50G 123
```

4. Modify each file in the `test_config` to point to the absolute path of this file.
    1. The `filename` parameter should be updated.

5. Make sure to perform a full write to the file; otherwise, the disk is not read during FIO test.
    1. It's recommanded to change one of the `test_config` file from random read to random write, which will write the full disk. Then you may change it back for the evaluation.

### cgroup
Linux cgroup allows fine-grain partition of resource. In this case, we use Linux cgroup to limit the file cache size to 4GB.

Here are some key steps to enable cgroup on Linux:

1. Modify `/etc/default/grub` 
    1. Append the following to the `GRUB_CMDLINE_LINUX_DEFAULT`: `cgroup_enable=memory cgroup_enable=cpuset cgroup_memory=1 systemd.unified_cgroup_hierarchy=1`
2. Apply the change
    1. `sudo update-grub`
    2. reboot

In the `figure_8.sh` we made a group called `cxl_mem_app` and `mem_remote`. Below is a snippt from our `/etc/cgconfig.conf`
```
group cxl_mem_app {
    memory {}
    cpuset {}
}

group cxl_mem_app/mem_remote {
    memory {}
    cpuset {}
}
```
You may apply the cgroup changes with `sudo cgconfigparser -l /etc/cgconfig.conf`

### System configuration
The `util_scripts/config_all.sh` is executed before each test within the testing scripts.

It does the following configurations:
* Lock CPU frequency 
* Disable frequency boosting
* Disable hyperthreading in software
* Disable NUMA balancing
* Stop `numad` if it exists
