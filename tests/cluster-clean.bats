#!/usr/bin/env bats

load './test_helper/bats-support/load'
load './test_helper/bats-assert/load'

function teardown() {
    make -j2 NODE_COUNT=1 clean
}

@test "test make clean (master + 1x node) being succesful." {
    run make -j2 NODE_COUNT=1 KUBE_NETWORK="none" clean
    assert_success
}

@test "test consecutive run of make clean (master + 1x node) being succesful." {
    run make -j2 NODE_COUNT=1 KUBE_NETWORK="none" clean
    assert_success
}

@test "test make status reporing two VMs 'not created' status." {
    run make -j2 NODE_COUNT=1 status
    assert_success
    assert_output --partial 'not created'
    assert [ $(echo "$output" | sed 's/not created/not created\n/g' | grep -c "not created") -eq 2 ]
}

@test "kubectl vagrant context removed." {
    run kubectl get nodes
    assert_failure
    assert_output --partial 'context was not found for specified context: k8s-vagrant-multi-node'
}
