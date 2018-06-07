#!/bin/bash
set -x

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit 1

NODE_COUNT="$(grep -Po 'NODE_COUNT = \K\w+$' Vagrantfile)"

SOURCE_IMAGE="$1"
DEST_IMAGE="$2"

docker tag "${SOURCE_IMAGE}" "${DEST_IMAGE}"

for vm in master {1..${NODE_COUNT}}; do
    docker save "${DEST_IMAGE}" | vagrant ssh "${vm}" -t -c 'sudo docker load' &
done
echo "Waiting for docker load jobs to finish ..."
wait
