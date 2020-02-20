#!/bin/sh

virsh net-define /dev/stdin <<EOF
<network connections='1' ipv6='yes'>
  <name>${CLUSTER_NAME}0</name>
  <uuid>2cb1df91-fb69-45a2-b670-e6e20d19890f</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr2' stp='on' delay='0'/>
  <mac address='52:54:00:fd:e7:6d'/>
  <ip address='${NODE_IP_NW}1' netmask='255.255.255.0'>
    <dhcp>
      <range start='${NODE_IP_NW}1' end='${NODE_IP_NW}254'/>
    </dhcp>
  </ip>
</network>
EOF
