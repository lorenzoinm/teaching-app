#!/bin/bash
echo "You must be root to run it"
echo "Make sure the container is already running"
echo "usage: $0 can0 style_transmitter"
echo
echo
CAN=$1
SERVICE=$2
DOCKERPID=$(docker inspect -f '{{.State.Pid}}' $2)
modprobe can-gw vxcan
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
    ip link add dev $CAN type vcan
    ip link set $CAN netns $DOCKERPID
    nsenter -t $DOCKERPID -n ip link set $CAN up
fi

if [[ $CAN == can* ]]
    then
    ip link add vxcan0 type vxcan peer name vxcan1 netns $DOCKERPID
    RULES=$(cangw -L)

    if [[ $RULES != *"cangw -A -s $CAN -d vxcan0 -e"* ]]
        then
        cangw -A -s $CAN -d vxcan0 -e
        else
        echo "Rule already exists: cangw -A -s $CAN -d vxcan0 -e"
    fi
    if [[ $RULES != *"cangw -A -s vxcan0 -d $CAN -e"* ]]
        then
        cangw -A -s vxcan0 -d $CAN -e
        else
        echo "Rule already exists: cangw -A -s vxcan0 -d $CAN -e "
    fi

    ip link set vxcan0 up
    ip link set $CAN type can bitrate 500000
    ip link set $CAN up
    nsenter -t $DOCKERPID -n ip link set vxcan1 up
fi
