#!/usr/bin/env bats

load './test_helper/bats-support/load'
load './test_helper/bats-assert/load'

@test "test make up (master + 1x node) being succesful." {
    run make ${TEST_MAKEFLAGS} NODE_COUNT=1 KUBE_NETWORK="none" up
    assert_success
}

@test "test consecutive run of make up (master + 1x node) being succesful." {
    run make ${TEST_MAKEFLAGS} NODE_COUNT=1 KUBE_NETWORK="none" up
    assert_success
}

@test "test make status reporting two running VMs." {
    run make ${TEST_MAKEFLAGS} NODE_COUNT=1 status
    assert_success
    refute_output --partial 'not created'
    assert_output --partial 'running '
    assert [ $(echo "$output" | sed 's/running /running \n/g' | grep -c "running ") -eq 2 ]
}
