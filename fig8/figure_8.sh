#/bin/bash

EXP_NAME=fig_8
SETUP_SCRIPT_DIR=../util_scripts/
ITERATION=3

MEM_NODE=("0" "8")
MEM_CFG=("4G")
BS_ARR=("4k" "8k" "16k" "32k" "64k" "128k" "256k" "512k")

FIO_CFG_PATH=./test_config

CGROUP_PATH=/sys/fs/cgroup/cxl_mem_app/mem_remote

# set
bash $SETUP_SCRIPT_DIR/config_all.sh
sudo cgconfigparser -l /etc/cgconfig.conf

# arg0: mem_node
# arg1: mem_size
# This limit the memory on mem_node, 
#       and cap the page cache size to mem_size
set_cgroup_cfg() {
    echo "Setting cgroup to node:$1, size:$2"
    sudo sh -c "echo 0-7 > ${CGROUP_PATH}/cpuset.cpus"
    sudo sh -c "echo $1 > ${CGROUP_PATH}/cpuset.mems"
    sudo sh -c "echo max > ${CGROUP_PATH}/memory.high"
    sudo sh -c "echo $2 > ${CGROUP_PATH}/memory.max"
    #cat ${CGROUP_PATH}/cpuset.cpus
    cat ${CGROUP_PATH}/cpuset.mems
    cat ${CGROUP_PATH}/memory.high
    cat ${CGROUP_PATH}/memory.max
}

for bs in ${BS_ARR[@]}; do
    RESULT_DIR=./result/${EXP_NAME}/${bs}
    TEST_CFG=${FIO_CFG_PATH}/fio-rand-read-zipf-${bs}.fio 
    mkdir -p $RESULT_DIR

    for mem_node in ${MEM_NODE[@]}; do
        for mem_cfg in ${MEM_CFG[@]}; do
            for ((i=0;i<$ITERATION;i++)); do
                echo "Testing node:${mem_node}, size:${mem_cfg}, blocksize:${bs} i:${i}"
                
                # set 
                bash $SETUP_SCRIPT_DIR/flush_page_cache.sh
                set_cgroup_cfg "${mem_node}" "${mem_cfg}"

                # run
                result_file=$RESULT_DIR/${mem_node}_${mem_cfg}_${i}.txt
                sudo cgexec -g memory:cxl_mem_app/mem_remote ./fio  $TEST_CFG > $result_file

                # parse
                #p99=`awk '/99.00/ {print $3}' $result_file | grep -Eo '[+-]?[0-9]+([.][0-9]+)?'`
                #iops=`awk '/IOPS/ {print $2}' $result_file | grep -Eo '[+-]?[0-9]+([.][0-9]+)?'`
                #p99=`awk '/99.00/ {print $2}' $result_file | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tail -n 1`
                #iops=`awk '/IOPS/ {print $2}' $result_file | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tail -n 1`
                #bw=`awk '/BW/ {print $3}' $result_file | grep -Eo '[+-]?[0-9]+([.][0-9]+)?'`
                #echo "$mem_cfg,$p99,$iops,$bw" >> $RESULT_DIR/${mem_node}.txt
            done
        done
    done
    cp $TEST_CFG $RESULT_DIR
done

