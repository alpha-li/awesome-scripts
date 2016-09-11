#!/bin/bash

# A simple Test script to implement a simple load balancer with DNAT.
# Use ./lb-with-dnat set_up to set up a experiment enviroment.
# Use ./lb-with-dnat tear_down to destroy your existing enviroment.
# Enjoy yourserlf!
#
#-----------------------------------------------------------------------------------------------------------------
#
# +---------------+
# | ns-server1    |
# |               |
# |               |
# |               |
# |  veth-s1-br2  |
# |     +---+     |        +--------+                                   +--------+
# +-----+-+-+-----+        |  br2   |                                   |        |
#         |            veth-br2-s1  |          +---------------+        | br1    |         +-------------+
#         |                +-+      |          |  ns-lb        |        |        |         | ns-client   |
#         +----------------+ |      |          |               |   veth-br1-lb   |         |             |
#                          +-+    +-+          +-+           +-+        +-+    +-+         +-+           |
#                          |      | +----------+ |           | +--------+ |    | +---------+ |veth-c-br1 |
#                          +-+    +-+          +-+           +-+        +-+    +-+         +-+           |
#         +----------------+ | veth-br2-lb  veth-lb-br2    veth-lb-br1  |      veth-br1-c  |             |
#         |                +-+      |          |               |        |        |         |             |
#         |            veth-br2-s2  |          +---------------+        |        |         +-------------+
# +-----+-+-+------+       |        |                                   |        |
# |     +---+      |       +--------+                                   +--------+
# |  veth-s2-br2   |
# |                |
# |                |
# |                |
# |ns-server2      |
# +----------------+                                                                                
#  +                                                    +   +-                                     -+
#  |                                                    |   |                                       |
#  +----------------------------------------------------+   +---------------------------------------+
#                   192.168.1.0/24                                    10.0.0.0/24
#
#
#-------------------------------------------------------------------------------------------------------------------


function set_up()
{
    ip link add br1 type bridge
    ip link set br1 up
    
    ip netns add ns-client
    ip link add veth-br1-c type veth peer name veth-c-br1 
    ip link set veth-c-br1 netns ns-client
    ip link set veth-br1-c master br1
    
    ip netns exec ns-client ip addr add 10.0.0.1/24 dev veth-c-br1
    ip netns exec ns-client ip link set veth-c-br1 up
    ip link set veth-br1-c up
    
    
    ip netns add ns-lb
    ip link add veth-br1-lb type veth peer name veth-lb-br1
    ip link set veth-lb-br1 netns ns-lb
    ip link set veth-br1-lb master br1
    
    ip link set veth-br1-lb up
    
    ip netns exec ns-lb ip addr add 10.0.0.2/24 dev veth-lb-br1
    ip netns exec ns-lb ip link set veth-lb-br1 up
    
    ip link add br2 type bridge
    ip link set br2 up
    
    ip link add veth-lb-br2 type veth peer name veth-br2-lb
    ip link set veth-lb-br2 up
    ip link set veth-br2-lb up
    
    ip link set veth-lb-br2 netns ns-lb
    ip netns exec ns-lb ip addr add 192.168.1.1/24 dev veth-lb-br2
    ip netns exec ns-lb ip link set veth-lb-br2 up
    
    ip link set veth-br2-lb master br2
    
    ip netns add ns-server1
    ip netns add ns-server2
    
    ip link add veth-br2-s1 type veth peer name veth-s1-br2
    ip link set veth-br2-s1 master br2
    ip link set veth-br2-s1 up
    ip link set veth-s1-br2 netns ns-server1
    ip netns exec ns-server1 ip addr add 192.168.1.101/24 dev veth-s1-br2
    ip netns exec ns-server1 ip link set veth-s1-br2 up
    ip netns exec ns-server1 ip route add default via 192.168.1.1
    
    
    ip link add veth-br2-s2 type veth peer name veth-s2-br2
    ip link set veth-br2-s2 master br2
    ip link set veth-br2-s2 up
    ip link set veth-s2-br2 netns ns-server2
    ip netns exec ns-server2 ip addr add 192.168.1.102/24 dev veth-s2-br2
    ip netns exec ns-server2 ip link set veth-s2-br2 up
    ip netns exec ns-server2 ip route add default via 192.168.1.1
    
    ip netns exec ns-lb echo "1" > /proc/sys/net/ipv4/ip_forward
    
    ip netns exec ns-lb iptables -t nat -A PREROUTING -p tcp -d 10.0.0.2 \
        -j DNAT --to-destination 192.168.1.101-192.168.1.102

    #Isolate internal and external network
    ip netns exec ns-lb iptables -t nat -A POSTROUTING -p tcp -o veth-lb-br2 \
        -j MASQUERADE
}

function tear_down()
{
    ip netns del ns-client
    ip netns del ns-lb
    ip netns del ns-server1
    ip netns del ns-server2

    ip link del br1
    ip link del br2
}



if [ "$1" == "set_up" ];then
    set_up
elif [ "$1" == "tear_down" ];then
    tear_down
else
    echo "Nothing to do ..."
fi
