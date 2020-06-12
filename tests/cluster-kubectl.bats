#!/usr/bin/env bats

load './test_helper/bats-support/load'
load './test_helper/bats-assert/load'

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
