#!/bin/bash

NUM_CORES=32
INCREMENTAL_ITER=10
STEPPING=4
CORE_CNT_START=4

SNC_NODE_CLOSER=4
CXL_NODE=8

ITLV_RATIO=(17 38 50 63 83)
#ITLV_RATIO=(5 10 15 20 25)

bash ../../util_scripts/config_all.sh

if [ ! -d ../results/ ]; then
    mkdir ../results/
fi

# Start testing
echo "[INFO] Test started"

mkdir -p "./results/fig_9a"

i=$CORE_CNT_START
while [ $i -le $NUM_CORES ]; do
    iter=$((INCREMENTAL_ITER*i))

    echo -n "[TEST] $i threads, iter: $iter, all ddr"

    #LATENCY=`sudo numactl --membind=$SNC_NODE_CLOSER ./bin/eval_baseline -d amazon_Office_Products -r $iter -c $i | awk '/Average Time/ {print $3}'`
    LATENCY=`sudo numactl  --membind=$SNC_NODE_CLOSER ./bin/eval_baseline -d amazon_Office_Products -r $iter -c $i | awk '/Average Time/ {print $3}'`
    echo $LATENCY >> ./results/fig_9a/100_0.txt
    echo " $LATENCY"

    echo -n "[TEST] $i threads, iter: $iter, all cxl"

    #LATENCY=`sudo numactl --membind=$CXL_NODE ./bin/eval_baseline -d amazon_Office_Products -r $iter -c $i | awk '/Average Time/ {print $3}'`
    LATENCY=`sudo numactl --membind=$CXL_NODE ./bin/eval_baseline -d amazon_Office_Products -r $iter -c $i | awk '/Average Time/ {print $3}'`
    echo $LATENCY >> ./results/fig_9a/0_100.txt
    echo " $LATENCY"

    for ratio in ${ITLV_RATIO[@]}; do
        bot=$ratio
        top=$((100-$bot))
        RESULT_NAME="${top}_${bot}"
        RESULT_FILE_NAME="./results/fig_9a/${RESULT_NAME}"

        sudo sysctl -w vm.numa_tier_interleave_top=$top 
        sudo sysctl -w vm.numa_tier_interleave_bot=$bot

        
        echo -n "[TEST] $i threads, iter: $iter, top: ${top}, bot: ${bot}"
        #LATENCY=`sudo numactl --interleave=$SNC_NODE_CLOSER,$CXL_NODE ./bin/eval_baseline -d amazon_Office_Products -r $iter -c $i | awk '/Average Time/ {print $3}'`
        LATENCY=`sudo numactl --interleave=$SNC_NODE_CLOSER,$CXL_NODE ./bin/eval_baseline -d amazon_Office_Products -r $iter -c $i | awk '/Average Time/ {print $3}'`

        echo $LATENCY >> ${RESULT_FILE_NAME}.txt
        echo " $LATENCY"
    done
    i=$(( $i + $STEPPING ))
done
