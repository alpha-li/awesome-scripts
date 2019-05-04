#!/bin/bash

# A simple Test script to implement a simple virtual netowrk with vxlan.
# Use ./vn-with-vxlan set_up to set up a experiment enviroment.
# Use ./vx-with-vxlan tear_down to destroy your existing enviroment.
# Enjoy yourserlf!
#
#-------------------------------------------------------------------------------------------------------------------


function set_up()
{
        ip link add veth-1 type veth peer name veth-2
	ip netns add ns1
	ip netns add ns2
        ip link set veth-1 netns ns1
	ip link set veth-2 netns ns2

	ip netns exec ns1 ip addr add 192.168.1.101/24 dev veth-1
	ip netns exec ns1 ip link set lo up
	ip netns exec ns1 ip link set veth-1 up


	ip netns exec ns2 ip addr add 192.168.1.102/24 dev veth-2
	ip netns exec ns2 ip link set lo up
	ip netns exec ns2 ip link set veth-2 up

        ip netns exec ns1 ip link add vxlan-101 type vxlan id 101 dstport 4789 remote 192.168.1.102 dev veth-1
	ip netns exec ns1 ip link add br0 type bridge
	ip netns exec ns1 ip link set br0 up
	ip netns exec ns1 ip link set vxlan-101 master br0
	ip netns exec ns1 ip link set vxlan-101 up
	ip netns exec ns1 ip link add veth-a-b type veth peer name veth-b-a
	ip netns exec ns1 ip link set veth-b-a master br0
	ip netns exec ns1 ip addr add 100.0.0.101/24 dev veth-a-b
	ip netns exec ns1 ip link set veth-a-b up
	ip netns exec ns1 ip link set veth-b-a up


        ip netns exec ns2 ip link add vxlan-101 type vxlan id 101 dstport 4789 remote 192.168.1.101 dev veth-2
	ip netns exec ns2 ip link add br0 type bridge
	ip netns exec ns2 ip link set br0 up
	ip netns exec ns2 ip link set vxlan-101 master br0
	ip netns exec ns2 ip link set vxlan-101 up
	ip netns exec ns2 ip link add veth-c-d type veth peer name veth-d-c
	ip netns exec ns2 ip link set veth-d-c master br0
	ip netns exec ns2 ip addr add 100.0.0.102/24 dev veth-c-d
	ip netns exec ns2 ip link set veth-c-d up
	ip netns exec ns2 ip link set veth-d-c up

}

function tear_down()
{
    ip netns del ns1
    ip netns del ns2
}



if [ "$1" == "set_up" ];then
    set_up
elif [ "$1" == "tear_down" ];then
    tear_down
else
    echo "Nothing to do ..."
fi
