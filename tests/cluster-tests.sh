#!/bin/bash

tearDown() {
    make -j3 NODE_COUNT=1 clean
}

testClusterUpFirst() {
    exec 5>&1
    CMD_OUTPUT="$(make -j3 NODE_COUNT=1 KUBE_NETWORK="none" up | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "make status exit code zero" "$rtrn"
    assertContains "make up was succesful" "$CMD_OUTPUT" "Your k8s-vagrant-multi-node Kuberenetes cluster should be ready now."
}

testClusterUpSecond() {
    exec 5>&1
    CMD_OUTPUT="$(make -j3 NODE_COUNT=1 KUBE_NETWORK="none" up | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "make status exit code zero" "$rtrn"
    assertContains "make up was succesful" "$CMD_OUTPUT" "Your k8s-vagrant-multi-node Kuberenetes cluster should be ready now."
}

testClusterStatusTwoRunning() {
    exec 5>&1
    CMD_OUTPUT="$(make -j3 NODE_COUNT=1 status | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "make status exit code zero" "$rtrn"
    assertNotContains "make status contains 'not created' VMs" "$CMD_OUTPUT" "not created"
    assertContains "make status contains at least one 'running' VM" "$CMD_OUTPUT" "running"
    assertEquals "make status reports two running VMs" 2 "$(echo "$CMD_OUTPUT" | sed 's/running /running \n/g' | grep -c "running ")"
}

testKubectlVersion() {
    exec 5>&1
    CMD_OUTPUT="$(kubectl version | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "kubectl version exit code zero" "$rtrn"
    assertEquals 2 "$(echo "$CMD_OUTPUT" | wc -l)"
    assertContains "kubectl version contains $KUBERNETES_VERSION server version" "$KUBERNETES_VERSION" "$(echo "$CMD_OUTPUT" | sed -n "2p")"
}

testKubectlGetNodesTwoNodes() {
    exec 5>&1
    CMD_OUTPUT="$(kubectl get nodes --no-headers=true | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "kubectl get nodes exit code zero" "$rtrn"
    assertEquals "kubectl get nodes contains 2 nodes" 2 "$(echo "$CMD_OUTPUT" | wc -l)"
}

testMakeCleanFirst() {
    exec 5>&1
    CMD_OUTPUT="$(make -j3 NODE_COUNT=1 KUBE_NETWORK="none" clean | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "make clean exit code zero" "$rtrn"
}

testMakeCleanSecond() {
    exec 5>&1
    CMD_OUTPUT="$(make -j3 NODE_COUNT=1 KUBE_NETWORK="none" clean | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "make clean exit code zero" "$rtrn"
}

testMakeStatusAfterMakeClean() {
    exec 5>&1
    CMD_OUTPUT="$(make -j3 NODE_COUNT=1 status | tee >(cat - >&5))"
    rtrn=$?

    assertTrue "make status exit code zero" "$rtrn"
    assertNotContains "make status contains 'running' VMs" "$CMD_OUTPUT" "running"
    assertContains "make status contains at least one 'not created' VM" "$CMD_OUTPUT" "not created"
    assertEquals "make status reports two 'not created' VMs" 2 "$(echo "$CMD_OUTPUT" | sed 's/not created/not created\n/g' | grep -c "not created")"
}

testKubectlContextRemoved() {
    exec 5>&1
    CMD_OUTPUT="$(kubectl version | tee >(cat - >&5))"
    rtrn=$?

    assertFalse "kubectl exit code non-zero" "$rtrn"
    assertContains "kubectl contains error that context does not exist" "$CMD_OUTPUT" "context was not found for specified context: k8s-vagrant-multi-node"
}

. ./tests/test_helper/shunit2/shunit2
