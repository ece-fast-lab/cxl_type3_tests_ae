#!/bin/bash

# Workload generator usage:
# ./wrk -D exp -t <num-threads> -c <num-conns> -d <duration> -L -s ./scripts/social-network/compose-post.lua http://localhost:8080/wrk2-api/post/compose -R <reqs-per-sec>
# ./wrk -D exp -t <num-threads> -c <num-conns> -d <duration> -L -s ./scripts/social-network/read-home-timeline.lua http://localhost:8080/wrk2-api/home-timeline/read -R <reqs-per-sec>
# ./wrk -D exp -t <num-threads> -c <num-conns> -d <duration> -L -s ./scripts/social-network/read-user-timeline.lua http://localhost:8080/wrk2-api/user-timeline/read -R <reqs-per-sec>
# Generate network:
# python3 scripts/init_social_graph.py --graph=<socfb-Reed98, ego-twitter, or soc-twitter-follows-mun>
# Process result:
# python3 process.py -i <input_folder> -o <output_folder>

NODE=$1
[ ! $2 ] && OUTPUT_PATH="report" || OUTPUT_PATH=$2 # if you dont want to run the workload, dont give the second argument
THREADS=12
CONNECTONS=128
DURATION=60
START_QPS=2000
STEP=2000
ITERATION=4

sudo docker compose down


# create output folder
[ ! -d $OUTPUT_PATH ] && mkdir $OUTPUT_PATH

# judge if there is a docker-compose running and if the services are on a specific node
NEED_SETUP=0
if [ -z "$(sudo docker ps | awk 'NR==2 {print $1}')" ]; then
    echo ""
    echo "[INFO] No containers are running"
    echo ""
    NEED_SETUP=1
elif [ -n "$(sudo docker ps | awk '/memcached-numa/ {print $1}')" ] && [ $NODE == "local" ]; then
    echo ""
    echo "[INFO] Shutting down remote containers."
    echo ""
    sudo docker-compose down
    NEED_SETUP=1
elif [ -z "$(sudo docker ps | awk '/memcached-numa/ {print $1}')" ] && [ $NODE == "remote" ]; then
    echo ""
    echo "[INFO] Shutting down local containers."
    echo ""
    sudo docker-compose down
    NEED_SETUP=1
fi

if [ $NEED_SETUP == 1 ]; then
    if [ $NODE == "local" ]; then
        cp ../docker-compose-local.yml ../docker-compose.yml
    elif [ $NODE == "remote" ]; then
        cp ../docker-compose-remote.yml ../docker-compose.yml
    fi

    # online the services
    echo ""
    echo "[INFO] Starting services..."
    echo ""
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    sudo docker-compose up -d
    echo ""
    echo "[INFO] Generating Network..."
    echo ""
    cd ..
    python3 scripts/init_social_graph.py --graph=socfb-Reed98
    cd wrk2
fi

if [ -z "$2" ]; then
    echo ""
    echo "[INFO] Services are up and loaded."
    exit 0
fi


echo ""
echo "[INFO] Start Testing..."
echo ""

for ((i=0;i<$ITERATION;i++)); do

    QPS=$(($START_QPS+$i*$STEP))

    # echo "[INFO] Sleep 30 sec..."
    # sleep 30

    echo "[TEST] Now running: QPS = $QPS "

    TARGET_MATCH="user-mongodb"
    TARGET_CONTAINER_ID=`sudo docker ps | grep $TARGET_MATCH | awk '{print $1;}'`
    echo $TARGET_MATCH
    echo $TARGET_CONTAINER_ID
    TARGET_PID=`sudo docker inspect -f '{{.State.Pid}}' $TARGET_CONTAINER_ID`
    echo $TARGET_PID
    : '
    sudo /opt/intel/oneapi/vtune/2023.0.0/bin64/vtune -collect uarch-exploration \
                                                        -data-limit=20480 \
                                                        -knob collect-memory-bandwidth=false \
                                                        -knob dram-bandwidth-limits=false \
                                                        -knob collect-frontend-bound=false \
                                                        -knob collect-bad-speculation=false \
                                                        -knob collect-memory-bound=true \
                                                        -knob collect-retiring=false \
                                                        -knob collect-core-bound=false \
                                                        -target-pid $TARGET_PID \
                                                        -result-dir $OUTPUT_PATH/vtune_out_${TARGET_MATCH}&
    '

    echo "wait 1 min ... "
    sleep 60
    echo "start testing ... "

    # ./wrk -D exp -t $THREADS -c $CONNECTONS -d $DURATION -L -s \
    #     ./scripts/social-network/compose-post.lua http://localhost:8080/wrk2-api/post/compose -R $QPS \
    #     > $OUTPUT_PATH/composePost_${NODE}_qps${QPS}_t${THREADS}_c${CONNECTONS}_d${DURATION}sec.txt

    # ./wrk -D exp -t $THREADS -c $CONNECTONS -d $DURATION -L -s \
    #     ./scripts/social-network/read-home-timeline.lua http://localhost:8080/wrk2-api/home-timeline/read -R $QPS \
    #     > $OUTPUT_PATH/homeTimeline_${NODE}_qps${QPS}_t${THREADS}_c${CONNECTONS}_d${DURATION}sec.txt

    # user
    : '
    ./wrk -D exp -t $THREADS -c $CONNECTONS -d $DURATION -L -s \
        ./scripts/social-network/read-user-timeline.lua http://localhost:8080/wrk2-api/user-timeline/read -R $QPS \
        > $OUTPUT_PATH/userTimeline_${NODE}_qps${QPS}_t${THREADS}_c${CONNECTONS}_d${DURATION}sec.txt&
    '


    # home
    : '
    ./wrk -D exp -t $THREADS -c $CONNECTONS -d $DURATION -L -s \
         ./scripts/social-network/read-home-timeline.lua http://localhost:8080/wrk2-api/home-timeline/read -R $QPS \
         > $OUTPUT_PATH/homeTimeline_${NODE}_qps${QPS}_t${THREADS}_c${CONNECTONS}_d${DURATION}sec.txt
    '

    # compose
    : '
    ./wrk -D exp -t $THREADS -c $CONNECTONS -d $DURATION -L -s \
        ./scripts/social-network/compose-post.lua http://localhost:8080/wrk2-api/post/compose -R $QPS \
        > $OUTPUT_PATH/composePost_${NODE}_qps${QPS}_t${THREADS}_c${CONNECTONS}_d${DURATION}sec.txt&
    '

    # mixed
    ./wrk -D exp -t $THREADS -c $CONNECTONS -d $DURATION -L -s \
        ./scripts/social-network/mixed-workload.lua http://localhost:8080/wrk2-api -R $QPS \
        > $OUTPUT_PATH/mixed_${NODE}_qps${QPS}_t${THREADS}_c${CONNECTONS}_d${DURATION}sec.txt&

    WRK_PID=$!

    echo "start monitoring ... "
    : '
    sudo /opt/intel/oneapi/vtune/2023.0.0/bin64/vtune -collect memory-access \
                                                        -duration=30 \
                                                        -data-limit=20480 \
                                                        -target-pid $TARGET_PID \
                                                        -result-dir $OUTPUT_PATH/vtune_out_${TARGET_MATCH}
    '

    echo "monitoring done, wait for wrk to finish ... "
    wait $WRK_PID 

    echo "[TEST] Test done"
    #sudo /opt/intel/oneapi/vtune/2023.0.0/bin64/vtune -r $OUTPUT_PATH/vtune_out_${TARGET_MATCH} -command stop

    echo "[TEST] parsing results ... "
    #sudo /opt/intel/oneapi/vtune/2023.0.0/bin64/vtune  -report summary -result-dir $OUTPUT_PATH/vtune_out_${TARGET_MATCH}/ -report-output $OUTPUT_PATH/vtune_summary.txt  

    sudo docker-compose down
    sleep 10
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    sudo docker-compose up -d
    cd ..
    python3 scripts/init_social_graph.py --graph=socfb-Reed98
    cd wrk2
done

#mv $OUTPUT_PATH result

echo ""
echo "[INFO] Test done."
echo ""
