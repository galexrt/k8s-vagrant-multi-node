#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR" || exit 1

docker tag build-ec779fd0/ceph-amd64 rook/ceph:master
docker tag build-ec779fd0/ceph-toolbox-amd64 rook/ceph-toolbox:master

for vm in master node1 node2 node3 node4; do
    echo $vm
    docker save rook/ceph:master | vagrant ssh $vm -t -c 'sudo docker load' &
    docker save rook/ceph-toolbox:master | vagrant ssh $vm -t -c 'sudo docker load' &
done
