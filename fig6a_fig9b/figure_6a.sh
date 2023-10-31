# workload r = a, s = b, t = c ....
YCSB_WORKLOADS=("r")
ITLV_RATIO=(75 50 25)
NODE=("local" "remote")
ITERATION=5

bash ../util_scripts/config_all.sh

# ===================================
#   test target QPS for each workload
# ===================================

# 100:0, 0:100 
for node in ${NODE[@]}; do
    for workload in ${YCSB_WORKLOADS[@]}; do
        for ((j=1;j<=$ITERATION;j++)); do
            echo "sleep 1"; sleep 1;
            echo "${workload} ${node} ${j}" 

            sudo ./run_redis.sh $workload $node "loop" figure_6a/tail_lats_${workload}_${node}_${j}
        done
    done
done

# 75:25, 50:50, 25:75
for ratio in ${ITLV_RATIO[@]}; do
    for workload in ${YCSB_WORKLOADS[@]}; do
        for ((j=1;j<=$ITERATION;j++)); do
            echo "sleep 1"; sleep 1;
            top=$ratio
            bot=$((100-$top))
            echo "${workload} ${top} ${bot} ${j}" 

            sudo sysctl -w vm.numa_tier_interleave_top=$top 
            sudo sysctl -w vm.numa_tier_interleave_bot=$bot

            sudo ./run_redis.sh $workload "interleave" "loop" figure_6a/tail_lats_${workload}_${top}_${bot}_${j}
        done
    done
done

# grep result:
# grep -r "99th" ./tail_latsr_local_1/ | grep "Run" | grep "READ" | sort -V
