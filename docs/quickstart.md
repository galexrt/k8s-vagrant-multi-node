# Quickstart

To start with the defaults, 1x master and 2x workers, run the following:

```shell
$ make up -j 3
```

The `-j3` will cause three VMs to be started in parallel to speed up the cluster creation.

> **NOTE** Your `kubectl` is automatically configured to use a context for the
> created cluster, after the master VM is started.
> The context is named after the directory the `Makefile` is in.

```shell
$ kubectl config current-context
k8s-vagrant-multi-node
$ kubectl get componentstatus
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health": "true"}
$ kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    4m        v1.17.3
node1     Ready     <none>    4m        v1.17.3
node2     Ready     <none>    4m        v1.17.3
```
