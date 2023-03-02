#!/bin/bash
echo "You must be root to run it"
echo "Make sure the container is already running"
echo "usage: $0 can0 style_transmitter"
echo
echo
CAN=$1
SERVICE=$2
DOCKERPID=$(docker inspect -f '{{.State.Pid}}' $2)

if [[ -z $DOCKERPID ]]
    then 
    echo "Service $2 has not been found"
    exit -1
fi

if [[ $CAN != can* ]] && [[ $CAN != vcan* ]]
    then
    echo "Input a valid can name: can0, vcan0, vcan1 ..."
    exit -1
fi

if [[ $CAN == vcan* ]]
    then
    ip link add dev vcan0 type vcan
fi
ip link set $CAN netns $DOCKERPID
if [[ $CAN == can* ]]
    then
    nsenter -t $DOCKERPID -n ip link set $CAN type can bitrate 500000
fi
nsenter -t $DOCKERPID -n ip link set $CAN up
