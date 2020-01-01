# k8s-vagrant-multi-node

This project was based on work from [coolsvap/kubeadm-vagrant](https://github.com/coolsvap/kubeadm-vagrant) by [@coolsvap](https://twitter.com/coolsvap), now it is mostly independent.

A demo of the start and destroy of a cluster can be found here: [README.md Demo section](#demo).

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Prerequisites](#prerequisites)
- [Hardware Requirements](#hardware-requirements)
- [Quickstart](#quickstart)
- [Different OS / Vagrantfiles](#different-os--vagrantfiles)
- [Usage](#usage)
	- [Starting the environment](#starting-the-environment)
	- [Faster (parallel) environment start](#faster-parallel-environment-start)
	- [Show status of VMs](#show-status-of-vms)
	- [Shutting down the environment](#shutting-down-the-environment)
	- [Copy local Docker image into VMs](#copy-local-docker-image-into-vms)
	- [Data inside VM](#data-inside-vm)
	- [Show `make` targets](#show-make-targets)
- [Variables](#variables)
- [Demo](#demo)
	- [Start Cluster](#start-cluster)
	- [Destroy Cluster](#destroy-cluster)

<!-- /TOC -->

## Prerequisites

* `make`
* `kubectl` - Optional when `KUBECTL_AUTO_CONF=false` (default `true`) is set.
* `grep`
* `cut`
* `rsync`
* Source for randomness (only used to generate a kubeadm token, when no custom `KUBETOKEN` is given):
	* `/dev/urandom`
	* `openssl` command - Fallback for when `/dev/urandom` is not available.
* Vagrant (>= `2.2.0`)
	* Tested with `2.2.2` (if you should experience issues, please upgrade to at least this version or higher)
* Virtualbox
	* Tested with `6.0.0` (if you should experience issues, please upgrade to at least this version or higher)
	* `VBoxManage` binary in `PATH`.

> **NOTE** `kubectl` is only needed when the `kubectl` auto configuration is enabled (default is enabled), to disable it set the variable `KUBECTL_AUTO_CONF` to `false`.
> For more information, see the [Variables](#variables) section.

## Hardware Requirements

* Master
    * CPU: 2 Cores
    * Memory: 2GB
* 1x Node:
    * CPU: 2 Core
    * Memory: 2GB

These resources can be changed by setting the according variables for the `make up` command, see [Variables section](#variables),

## Quickstart

To start with the defaults, 1x master and 2x workers, run the following:
```
$ make up -j 3
```
The `-j3` will cause three VMs to be started in parallel to speed up the cluster creation.
> **NOTE** Your `kubectl` is automatically configured to use a context for the
> created cluster, after the master VM is started.
> The context is named after the directory the `Makefile` is in.

```
$ kubectl config current-context
k8s-vagrant-multi-node
$ kubectl get componentstatus
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health": "true"}
$ kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    4m        v1.10.4
node1     Ready     <none>    4m        v1.10.4
node2     Ready     <none>    4m        v1.10.4
```

## Different OS / Vagrantfiles

There are multiple sets of Vagrantfiles available (see [`vagrantfiles/`](/vagrantfiles/)) which can be used to use a different OS for the Kubernetes environment.

List of currently available Vagrantfile sets:

| Name     | Container Runtime                           | OS Version   | Special Notes                                                                                                                           |
| -------- | ------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| `centos` | [Docker/Moby](https://github.com/moby/moby) | CentOS 7     | N/A                                                                                                                                     |
| `fedora` | [Docker/Moby](https://github.com/moby/moby) | Fedora 29    | N/A                                                                                                                                     |
| `ubuntu` | [Docker/Moby](https://github.com/moby/moby) | Ubuntu 18.04 | `canal` is used here due to issues with Ubuntu. Google DNS Servers are used due to resolution issues with the ubuntu Vagrant Box image. |

To use a different set than the default `fedora` one's, add `BOX_OS=__NAME__` (where `__NAME__` is, e.g., `fedora`).

## Usage

### Starting the environment

To start up the Vagrant Kubernetes multi node environment with the default of two worker nodes + a master (not parallel) run:
```
$ make up
```
> **NOTE** Your `kubectl` is automatically configured to use a context for the
> created cluster, after the master VM is started.
> The context is named after the directory the `Makefile` is in.

### Faster (parallel) environment start

To start up 4 VMs in parallel run (`-j` flag does not control how many (worker) VMs are started, the `NODE_COUNT` variable is used for that):
```
$ NODE_COUNT=3 make up -j4
```
The flag `-j CORES/THREADS` allows yout to set how many VMs (Makefile targets) will be run at the same time.
You can also use `-j $(nproc)` to start as many VMs as cores/threads you have in your machine.
So to start up all VMs (master and three nodes) in parallel, you would add one to the chosen `NODE_COUNT`.

### Show status of VMs

```
$ make status
master                    not created (virtualbox)
node1                     not created (virtualbox)
node2                     not created (virtualbox)
```

### Shutting down the environment

To destroy the Vagrant environment run:
```
$ make clean
$ make clean-data
```

### Copy local Docker image into VMs

The `make load-image` target can be used to copy a docker image from your local docker daemon to all the VMs in your cluster.
The `IMG` variable can be expressed in a few ways, for example:
```
$ make load-image IMG=your_name/your_image_name:your_tag
$ make load-image IMG=your_name/your_image_name
$ make load-image IMG=my-private-registry.com/your_name/your_image_name:your_tag
```

You can also specify a new image name and tag to use after the image has been copied to the VM's by setting the `TAG` variable.
This will not change the image/tag in your local docker daemon, it will only affect the image in the VM's.
```
$ make load-image IMG=repo/image:tag TAG=new_repo/new_image:new_tag
```

### Data inside VM

See the `data/VM_NAME/` directories, where `VM_NAME` is for example `master`.

### Show `make` targets

```
$ make help
Usage: make [TARGET ...]

clean-data                     Remove data (shared folders) and disks of all VMs (master and nodes).
clean-force                    Remove all drives which should normally have been removed by the normal clean-master or clean-node-% targets.
clean                          Destroy master and node VMs, delete data and the kubectl context.
clean-master                   Remove the master VM and the kubectl context.
clean-node-%                   Remove a node VM, where `%` is the number of the node.
clean-nodes                    Remove all node VMs.
help                           Show this help menu.
kubectl                        Configure kubeconfig context for the cluster using `kubectl config` (automatically done by `up` target).
kubectl-delete                 Delete the created CLUSTER_NAME context from the kubeconfig (uses kubectl).
load-image                     Load local/pulled Docker image into master and all node VMs.
load-image-master              Load local/pulled image into master VM.
load-image-node-%              Load local/pulled image into node VM, where `%` is the number of the node.
load-image-nodes               Load local/pulled Docker image into all node VMs.
preflight                      Run checks and gather variables, used for the the `up` target.
pull                           Add and download, or update the box image on the host.
ssh-master                     SSH into the master VM.
ssh-node-%                     SSH into a node VM, where `%` is the number of the node.
start-master                   Start up master VM (automatically done by `up` target).
start-node-%                   Start node VM, where `%` is the number of the node.
start-nodes                    Create and start all node VMs by utilizing the `node-X` target (automatically done by `up` target).
status-master                  Show status of the master VM.
status-nodes                   Show status of all node VMs.
status-node-%                  Show status of a node VM, where `%` is the number of the node.
status                         Show status of master and all node VMs.
stop-master                    Stop/Halt the master VM.
stop-nodes                     Stop/Halt all node VMs.
stop-node-%                    Stop/Halt a node VM, where `%` is the number of the node.
stop                           Stop/Halt master and all nodes VMs.
token                          Generate a kubeadm join token, if needed (token file is `DIRECTORY_OF_MAKEFILE/.vagrant/KUBETOKEN`).
up                             Start Kubernetes Vagrant multi-node cluster. Creates, starts and bootsup the master and node VMs.
vagrant-reload-master          Run vagrant reload for master VM.
vagrant-reload-node-%          Run `vagrant reload` for specific node  VM.
vagrant-reload-nodes           Run `vagrant reload` for all node VMs.
vagrant-reload                 Run vagrant reload on master and nodes.
versions                       Print the "imporant" tools versions out for easier debugging.
```

## Variables

| Variable Name                   | Default Value            | Description                                                                                                                                                                                                                            |
| ------------------------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BOX_OS`                        | `fedora`                 | Which set of Vagrantfiles to use to start the VMs.                                                                                                                                                                                     |
| `BOX_IMAGE`                     | ``                       | Set the VM box image to use (only for override purposes).                                                                                                                                                                              |
| `DISK_COUNT`                    | `1`                      | Set how many additional disks will be added to the VMs.                                                                                                                                                                                |
| `DISK_SIZE_GB`                  | `25` GB                  | Size of additional disks added to the VMs.                                                                                                                                                                                             |
| `MASTER_CPUS`                   | `2` Core                 | Amount of cores to use for the master VM.                                                                                                                                                                                              |
| `MASTER_MEMORY_SIZE_GB`         | `2` GB                   | Size of memory (in GB) to be allocated for the master VM.                                                                                                                                                                              |
| `NODE_CPUS`                     | `2`                      | Amount of cores to use for each node VM.                                                                                                                                                                                               |
| `NODE_MEMORY_SIZE_GB`           | `2` GB                   | Size of memory (in GB) to be allocated for each node VM.                                                                                                                                                                               |
| `NODE_COUNT`                    | `2`                      | How many worker nodes should be spawned.                                                                                                                                                                                               |
| `MASTER_IP`                     | `192.168.26.10`          | The Kubernetes master node IP.                                                                                                                                                                                                         |
| `NODE_IP_NW`                    | `192.168.26.`            | The first three parts of the IPs used for the nodes.                                                                                                                                                                                   |
| `POD_NW_CIDR`                   | `10.244.0.0/16`          | The Pod (container) network CIDR used for the CNI.                                                                                                                                                                                     |
| `K8S_DASHBOARD`                 | `false`                  | Install the Kubernetes dashboard addon.                                                                                                                                                                                                |
| `K8S_DASHBOARD_VERSION`         | `v1.10.1`                | The Kubernetes dashboard addon version. Note it is recommended to at least version `1.10.1`.                                                                                                                                           |
| `CLUSTER_NAME`                  | `k8s-vagrant-multi-node` | The name of the directory the Makefile is in. **This is not the Kubernetes cluster name**, due to `kubeadm init` limitations.                                                                                                          |
| `KUBETOKEN`                     | `""` (empty)             | The `kubeadm` "join" token to use. Will be generated automatically using `/dev/urandom/` when empty.                                                                                                                                   |
| `KUBEADM_INIT_FLAGS`            | `""` (empty)             | The `kubeadm init` flags to use. (When `KUBERNETES_VERSION` is set and `KUBEADM_INIT_FLAGS` is empty, `KUBEADM_INIT_FLAGS` will automatically be set to `--kubernetes-version=$KUBERNETES_VERSION`).                                   |
| `KUBEADM_JOIN_FLAGS`            | `""` (empty)             | The `kubeadm join` flags to use.                                                                                                                                                                                                       |
| `KUBERNETES_VERSION`            | `""` (empty)             | The `kubeadm` and `kubelet` package and API server version to install. Must be a fully qualified version string, e.g., `1.15.3` and not just `1.15`.                                                                                   |
| `KUBERNETES_PKG_VERSION_SUFFIX` | `""` (empty)             | String which will be appended to the `kubeadm` and `kubelet` package versions when installed (only used for `vagrantfiles/ubuntu`).                                                                                                    |
| `KUBE_PROXY_IPVS`               | `false`                  | Enable IPVS kernel modules to then use IPVS for the kube-proxy.                                                                                                                                                                        |
| `KUBE_NETWORK`                  | `flannel`                | What CNI to install, if empty don't install any CNI. `flannel`, `canal` and `calico` are supported options. Ubuntu CNI is forced to use `canal` and can't be changed (see [Different OS / Vagrantfiles](#different-os--vagrantfiles)). |
| `KUBECTL_AUTO_CONF`             | `true`                   | If `kubectl` should be  automatically configured to be able to talk with the cluster (if disabled, removes need for `kubectl` binary).                                                                                                 |

## Demo

Please note that these terminal recordings are currently outdated.

### Start Cluster

[![asciicast](https://asciinema.org/a/186375.png)](https://asciinema.org/a/186375)

### Destroy Cluster

[![asciicast](https://asciinema.org/a/186376.png)](https://asciinema.org/a/186376)

## Creating an Issue
Please attach the `make versions` output to the issue as is shown in the issue template. This makes debugging easier.
