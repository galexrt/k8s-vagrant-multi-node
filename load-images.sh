#!/bin/bash
set -x

getVMs() {
    vagrant status 2>/dev/null | grep "$2"
}

if [ $# -lt 2 ]; then
    echo "Not enough args given."
    echo "$0 [SOURCE_IMAGE] [DEST_IMAGE]"
    exit 2
fi

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit 1

SOURCE_IMAGE="$1"
DEST_IMAGE="$2"

docker tag "${SOURCE_IMAGE}" "${DEST_IMAGE}"

for vm in master; do
    docker save "${DEST_IMAGE}" | vagrant ssh "${vm}" -t -c 'sudo docker load' &
done

for vm in $(getVMs "node*"); do
    docker save "${DEST_IMAGE}" | VAGRANT_VAGRANTFILE=Vagrantfile_nodes vagrant ssh "${vm}" -t -c 'sudo docker load' &
done

echo "Waiting for docker load jobs to finish ..."
wait
