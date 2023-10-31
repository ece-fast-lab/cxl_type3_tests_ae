NODE=$1
THREADS=12
CONNECTONS=128
DURATION=60
START_QPS=8000
STEP=2000
ITERATION=1


sudo docker compose down
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
sudo sh -c "echo 0 > /proc/sys/kernel/numa_balancing"
mkdir -p fig_6b
mkdir -p fig_6c
mkdir -p fig_6d

if [ $NODE == "local" ]; then
    cp ../docker-compose-local-snc.yml ../docker-compose.yml
elif [ $NODE == "remote" ]; then
    cp ../docker-compose-remote-snc.yml ../docker-compose.yml
fi

echo ""
echo "[INFO] Wait 10 sec, Start Testing..."
echo ""

# ===============================================
#       Testing functions, arg = targe QPS
# ===============================================


# for the mix ratio, we are testing with the default ratio of requests
test_mixed() {
    ./wrk -D exp -t $THREADS -c $CONNECTONS -d $DURATION -L -s \
        ./scripts/social-network/mixed-workload.lua http://localhost:8080/wrk2-api -R $1 \
        > ./fig_6d/mixed_${NODE}_qps${QPS}_t${THREADS}_c${CONNECTONS}_d${DURATION}sec.txt
}

PCM_PATH=/home/yans3/pcm/build/bin/

start_pcm() {
    sudo $PCM_PATH/pcm-memory 1 -csv=${1}_pcm-memory.txt&
    sleep 5
    sudo $PCM_PATH/pcm-latency 1 > ${1}_pcm-latency.txt&
    sleep 5
    sudo $PCM_PATH/pcm 1 -csv=${1}_pcm.txt&
    sleep 5
}

stop_pcm() {
    sudo pkill -f pcm
}

for ((i=0;i<$ITERATION;i++)); do
    QPS=$(($START_QPS+$i*$STEP))
    echo "[TEST] Now running: QPS = $QPS "

    # Staring images
    cd ..; sudo docker compose up -d; sleep 10;
    # Load network
    python3 scripts/init_social_graph.py --graph=socfb-Reed98
    cd wrk2;

    mkdir -p "./fig_6d/${NODE}/" 
    start_pcm "./fig_6d/${NODE}/" 

    echo "wait 1 min ... "
    sleep 60
    echo "start testing ... "

    # commence test
    test_mixed $QPS

    stop_pcm

    # Reset
    echo "done, stopping docker images ..."; sudo docker compose down; sleep 10
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
done

echo ""
echo "[INFO] Test done."
echo ""
