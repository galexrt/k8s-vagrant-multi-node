#!/usr/bin/env bats

load './test_helper/bats-support/load'
load './test_helper/bats-assert/load'

@test "test make up (master + 1x node) being succesful." {
    run make -j3 NODE_COUNT=1 KUBE_NETWORK="none" up
    assert_success
}

@test "test consecutive run of make up (master + 1x node) being succesful." {
    run make -j3 NODE_COUNT=1 KUBE_NETWORK="none" up
    assert_success
}

@test "test make status reporting two running VMs." {
    run make -j3 NODE_COUNT=1 status
    assert_success
    refute_output --partial 'not created'
    assert_output --partial 'running '
    assert [ $(echo "$output" | sed 's/running /running \n/g' | grep -c "running ") -eq 2 ]
}

@test "kubectl version returning proper version and without error." {
    run kubectl version
    assert_success
    assert_line --index 1 --partial "$KUBERNETES_VERSION"
}

@test "kubectl get nodes returns two nodes." {
    run kubectl get nodes --no-headers=true
    assert_success
    assert [ $(echo "$output" | wc -l) -eq 2 ]
}
