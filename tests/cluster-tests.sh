#!/bin/bash

# unbuffer from the `expect` package is used for debuffering the `make` outputs
# The depending on the distro, `expect` can be in the `expect-dev` or
# `expect` package
if ! command -v unbuffer > /dev/null 2>&1; then
    echo "unbuffer: command not found. exit 1"
    exit 1
fi

oneTimeTearDown() {
    make -j3 NODE_COUNT=1 clean
}

testClusterUpFirst() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; unbuffer make -d -j3 NODE_COUNT=1 KUBE_NETWORK="none" up 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "make status exit code zero" "$rtrn"
    assertContains "make up was succesful" "$CMD_OUTPUT" "Your k8s-vagrant-multi-node Kuberenetes cluster should be ready now."
}

testClusterUpSecond() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; unbuffer make -j3 NODE_COUNT=1 KUBE_NETWORK="none" up 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "make status exit code zero" "$rtrn"
    assertContains "make up was succesful" "$CMD_OUTPUT" "Your k8s-vagrant-multi-node Kuberenetes cluster should be ready now."
}

testClusterStatusTwoRunning() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; unbuffer make -j3 NODE_COUNT=1 status 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "make status exit code zero" "$rtrn"
    assertNotContains "make status contains 'not created' VMs" "$CMD_OUTPUT" "not created"
    assertContains "make status contains at least one 'running' VM" "$CMD_OUTPUT" "running"
    assertEquals "make status reports two running VMs" 2 "$(echo "$CMD_OUTPUT" | sed 's/running /running \n/g' | grep -c "running ")"
}

testKubectlVersion() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; kubectl version 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "kubectl version exit code zero" "$rtrn"
    assertEquals 2 "$(echo "$CMD_OUTPUT" | wc -l)"
    assertContains "kubectl version server version $KUBERNETES_VERSION" "$(echo "$CMD_OUTPUT" | sed -n "2p")" "$KUBERNETES_VERSION"
}

testKubectlGetNodesTwoNodes() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; kubectl get nodes --no-headers=true 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "kubectl get nodes exit code zero" "$rtrn"
    assertEquals "kubectl get nodes contains 2 nodes" 2 "$(echo "$CMD_OUTPUT" | wc -l)"
}

testMakeCleanFirst() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; unbuffer make -j3 NODE_COUNT=1 KUBE_NETWORK="none" clean 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "make clean exit code zero" "$rtrn"
}

testMakeCleanSecond() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; unbuffer make -j3 NODE_COUNT=1 KUBE_NETWORK="none" clean 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "make clean exit code zero" "$rtrn"
}

testMakeStatusAfterMakeClean() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; unbuffer make -j3 NODE_COUNT=1 status 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertTrue "make status exit code zero" "$rtrn"
    assertNotContains "make status contains 'running' VMs" "$CMD_OUTPUT" "running"
    assertContains "make status contains at least one 'not created' VM" "$CMD_OUTPUT" "not created"
    assertEquals "make status reports two 'not created' VMs" 2 "$(echo "$CMD_OUTPUT" | sed 's/not created/not created\n/g' | grep -c "not created")"
}

testKubectlContextRemoved() {
    echo "=== BEGIN COMMAND OUTPUT ==="
    exec 5>&1
    CMD_OUTPUT="$(set -o pipefail; kubectl version 2>&1 | tee >(cat - >&5))"
    rtrn=$?
    echo "=== END COMMAND OUTPUT ==="

    assertNotEquals "kubectl exit code non-zero" "0" "$rtrn"
    assertContains "kubectl contains error that context does not exist" "$CMD_OUTPUT" "context was not found for specified context: k8s-vagrant-multi-node"
}

. ./tests/test_helper/shunit2/shunit2
