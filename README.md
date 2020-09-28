# k8s-vagrant-multi-node

[![Build Status](https://travis-ci.org/galexrt/k8s-vagrant-multi-node.svg?branch=master)](https://travis-ci.org/galexrt/k8s-vagrant-multi-node)

This project was based on work from [coolsvap/kubeadm-vagrant](https://github.com/coolsvap/kubeadm-vagrant) by [@coolsvap](https://twitter.com/coolsvap), now it is mostly independent.

A demo of the start and destroy of a cluster can be found here: [README.md Demo section](#demo).

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->
- [k8s-vagrant-multi-node](#k8s-vagrant-multi-node)
  - [Prerequisites](#prerequisites)
  - [Hardware Requirements](#hardware-requirements)
  - [Quickstart](#quickstart)
  - [VM OS Selection](#vm-os-selection)
  - [Usage](#usage)
    - [Starting the environment](#starting-the-environment)
    - [Faster (parallel) environment start](#faster-parallel-environment-start)
    - [Show status of VMs](#show-status-of-vms)
    - [Shutting down the environment](#shutting-down-the-environment)
    - [Copy local Docker image into VMs](#copy-local-docker-image-into-vms)
    - [Data inside VM](#data-inside-vm)
    - [`make` Targets](#make-targets)
  - [Configuration / Variables](#configuration--variables)
  - [Troubleshooting](#troubleshooting)
  - [Demo](#demo)
  - [Creating an Issue](#creating-an-issue)

<!-- /TOC -->

## Prerequisites

* `make`
* `kubectl` - Optional when `KUBECTL_AUTO_CONF` is set to `false` (default: `true`).
* `grep`
* `cut`
* `rsync`
* Source for randomness (only used to generate a kubeadm token, when no custom `KUBETOKEN` is given):
  * `/dev/urandom`
  * `openssl` command - Fallback for when `/dev/urandom` is not available.
* Vagrant (>= `2.2.0`)
  * Tested with `2.2.2` (if you should experience issues, please upgrade to at least this Vagrant version or higher)
  * Plugins
    * `vagrant-reload` **REQUIRED** For `BOX_OS=fedora` (set by default) and when using the `vagrant-reload*` targets, the `vagrant-reload` plugin is needed. An automatic attempt to install the plugin is made. To install manually run one of the following commands:
      * `make vagrant-plugins` or
      * `vagrant plugin install vagrant-reload`
* Vagrant Provider (one of the following two is needed)
  * libvirt (`vagrant plugin install vagrant-libvirt`)
    * Tested with `libvirtd` version `5.10.0`.
    * Libvirt support is still a bit experimental and can be unstable (e.g., VMs not getting IPs).
      * Troubleshooting: If your VM creation is hanging at `Waiting for domain to get an IP address...`, using `virsh` run `virsh force reset VM_NAME` (`VM_NAME` can be obtained using `virsh list` command) or in virt-manager `Force Reset` on the VM.
  * Virtualbox (**WARNING** VirtualBox seems to hang the Makefile randomly for some people, `libvirt` is recommended)
    * Tested with `6.0.0` (if you should experience issues, please upgrade to at least this version or higher)
    * `VBoxManage` binary in `PATH`.

> **NOTE** `kubectl` is only needed when the `kubectl` auto configuration is enabled (default is enabled), to disable it set the variable `KUBECTL_AUTO_CONF` to `false`.
> For more information, see the [Configuration / Variables doc page](docs/configuration.md).

## Hardware Requirements

* Master
  * CPU: 2 Cores (`MASTER_CPUS`)
  * Memory: 2GB (`MASTER_MEMORY_SIZE_GB`)
* 1x Node:
  * CPU: 1 Core (it is recommended to use at least 2 Cores; `NODE_CPUS`)
  * Memory: 2GB (it is recommended to use more than 2GB; `NODE_MEMORY_SIZE_GB`)

These resources can be changed by setting the according variables for the `make up` command, see [Configuration / Variables doc page](docs/configuration.md).

## Quickstart

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

## VM OS Selection

There are multiple sets of Vagrantfiles available (see [`vagrantfiles/`](/vagrantfiles/)) which can be used to use a different OS for the Kubernetes environment.

See [VM OS Selection doc page](docs/vm-os-selection.md).

## Usage

Also see [Usage doc page](docs/usage.md).

### Starting the environment

To start up the Vagrant Kubernetes multi node environment with the default of two worker nodes + a master (not parallel) run:

```shell
$ make up
```

> **NOTE** Your `kubectl` is automatically configured to use a context for the
> created cluster, after the master VM is started.
> The context is named after the directory the `Makefile` is in.

### Faster (parallel) environment start

To start up 4 VMs in parallel run (`-j` flag does not control how many (worker) VMs are started, the `NODE_COUNT` variable is used for that):

```shell
$ NODE_COUNT=3 make up -j4
```

The flag `-j CORES/THREADS` allows yout to set how many VMs (Makefile targets) will be run at the same time.
You can also use `-j $(nproc)` to start as many VMs as cores/threads you have in your machine.
So to start up all VMs (master and three nodes) in parallel, you would add one to the chosen `NODE_COUNT`.

### Show status of VMs

```shell
$ make status
master                    not created (virtualbox)
node1                     not created (virtualbox)
node2                     not created (virtualbox)
```

### Shutting down the environment

To destroy the Vagrant environment run:

```shell
$ make clean
$ make clean-data
```

### Copy local Docker image into VMs

The `make load-image` target can be used to copy a docker image from your local docker daemon to all the VMs in your cluster.
The `IMG` variable can be expressed in a few ways, for example:

```shell
$ make load-image IMG=your_name/your_image_name:your_tag
$ make load-image IMG=your_name/your_image_name
$ make load-image IMG=my-private-registry.com/your_name/your_image_name:your_tag
```

You can also specify a new image name and tag to use after the image has been copied to the VM's by setting the `TAG` variable.
This will not change the image/tag in your local docker daemon, it will only affect the image in the VM's.

```shell
$ make load-image IMG=repo/image:tag TAG=new_repo/new_image:new_tag
```

### Data inside VM

See the `data/VM_NAME/` directories, where `VM_NAME` is for example `master`.

### `make` Targets

See [`make` Targets doc page](docs/make-targets.md).

## Configuration / Variables

See [Configuration / Variables doc page](docs/configuration.md).

## Troubleshooting

See [Troubleshooting doc page](docs/troubleshooting.md).

## Demo

See [Demo doc page](docs/demo.md).

***

## Creating an Issue

Please attach the output of the `make versions` command to the issue as is shown in the issue template. This makes debugging easier.
