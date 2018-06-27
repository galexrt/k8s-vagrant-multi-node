# k8s-vagrant-multi-node
This project is based on work from [coolsvap/kubeadm-vagrant](https://github.com/coolsvap/kubeadm-vagrant) by [@coolsvap](https://twitter.com/coolsvap).

A demo of the start and destroy of a cluster can be found here: [README.md Demo section](#demo).

## Prerequisites
* `make`
* Vagrant (tested with `2.1.1`)
* Virtualbox
* `rsync`
* `/dev/urandom` (only used to generate a kubeadm token, when no custom `KUBETOKEN` is given)

## Hardware Requirements
* Master
    * CPU: 2 Cores
    * Memory: 2GB
* 1x Node:
    * CPU: 1 Core
    * Memory: 1GB

These resources can currently only be changed by editing `Vagrantfile` and `Vagrantfile_nodes` directly,
but will probably be configurable by environment variables in the future.

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
clean                          Destroy master and node VMs, and delete data.
clean-data                     Remove data (shared folders) and disks of all VMs (master and nodes).
clean-master                   Remove the master VM.
clean-node-%                   Remove a node VM, where `%` is the number of the node.
clean-nodes                    Remove all node VMs.
help                           Show this help menu.
kubectl                        Configure kubeconfig context for the cluster using `kubectl config` (automatically done by `up` target).
load-image                     Load local/pulled Docker image into master and all node VMs.
load-image-master              Load local/pulled image into master VM.
load-image-node-%              Load local/pulled image into node VM, where `%` is the number of the node.
load-image-nodes               Load local/pulled Docker image into all node VMs.
preflight                      Run checks and gather variables, used for the the `up` target.
ssh-master                     SSH into the master VM.
ssh-node-%                     SSH into a node VM, where `%` is the number of the node.
start-master                   Start up master VM (automatically done by `up` target).
start-nodes                    Create and start all node VMs by utilizing the `node-X` target (automatically done by `up` target).
start-node-%                   Start node VM, where `%` is the number of the node.
status-master                  Show status of the master VM.
status-node-%                  Show status of a node VM, where `%` is the number of the node.
status-nodes                   Show status of all node VMs.
status                         Show status of master and all node VMs.
stop-master                    Stop/Halt the master VM.
stop-nodes                     Stop/Halt all node VMs.
stop-node-%                    Stop/Halt a node VM, where `%` is the number of the node.
stop                           Stop/Halt master and all nodes VMs.
token                          Generate a kubeadm join token, if needed (token file is `DIRECTORY_OF_MAKEFILE/.vagrant/KUBETOKEN`).
up                             Start Kubernetes Vagrant multi-node cluster. Creates, starts and bootsup the master and node VMs.
```

## Variables
| Variable Name           | Default Value            | Description                                                                                                                                                      |
| ----------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BOX_IMAGE`             | `generic/fedora27`       | Set the VMs box image to use.                                                                                                                                    |
| `DISK_COUNT`            | `1`                      | Set how many additional disks will be added to the VMs.                                                                                                          |
| `DISK_SIZE_GB`          | `10` GB                  | Size of additional disks added to the VMs.                                                                                                                       |
| `MASTER_CPUS`           | `1` Core                 | Amount of cores to use for the master VM.                                                                                                                        |
| `NODE_COUNT`            | `2`                      | How many worker nodes should be spawned.                                                                                                                         |
| `MASTER_IP`             | `192.168.26.10`          | The Kubernetes master node IP.                                                                                                                                   |
| `NODE_IP_NW`            | `192.168.26.`            | The first three parts of the IPs used for the nodes.                                                                                                             |
| `POD_NW_CIDR`           | `10.244.0.0/16`          | The Pod (container) network CIDR.                                                                                                                                |
| `K8K8S_DASHBOARD`       | `false`                  | Install the Kubernetes dashboard addon.                                                                                                                          |
| `CLUSTER_NAME`          | `k8s-vagrant-multi-node` | The name of the directory the Makefile is in.                                                                                                                    |
| `KUBETOKEN`             | `""` (empty)             | The `kubeadm` "join" token to use. Will be generated automatically using `/dev/urandom/` when empty.                                                             |
| `KUBEADM_INIT_FLAGS`    | `""` (empty)             | The `kubeadm init` flags to use.                                                                                                                                 |
| `KUBEADM_JOIN_FLAGS`    | `""` (empty)             | The `kubeadm join` flags to use.                                                                                                                                 |
| `KUBERNETES_VERSION`    | `""` (empty)             | The `kubeadm` and `kubelet` package and API server version to install (`KUBEADM_INIT_FLAGS` will be set to `--kubernetes-version=$KUBERNETES_VERSION` if unset). |
| `MASTER_MEMORY_SIZE_GB` | `2` GB                   | Size of memory (in GB) to be allocated for the master VM.                                                                                                        |
| `NODE_CPUS`             | `1`                      | Amount of cores to use for each node VM.                                                                                                                         |
| `NODE_MEMORY_SIZE_GB`   | `1` GB                   | Size of memory (in GB) to be allocated for each node VM.                                                                                                         |

## Demo
### Start Cluster
[![asciicast](https://asciinema.org/a/186375.png)](https://asciinema.org/a/186375)

### Destroy Cluster
[![asciicast](https://asciinema.org/a/186376.png)](https://asciinema.org/a/186376)
