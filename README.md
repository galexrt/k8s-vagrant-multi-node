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

These values can currently only be changed by editing `Vagrantfile` and `Vagrantfile_nodes` directly,
but will probably be configurable by environment variables in the future.

## Quickstart
To start with the defaults, 1x master and 2x workers, run the following:
```
$ make up -j 3
$ kubectl get componentstatus
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health": "true"}
$ kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    9m        v1.10.4
node1     Ready     <none>    9m        v1.10.4
node2     Ready     <none>    9m        v1.10.4
```
The `-j3` will cause three targets, in this VMs, to be started at the same time.

## Usage
### Starting the environment
To start up the Vagrant Kubernetes multi node environment (non parallel) run:
```
make up
```
To start up 4 VMs in parallel run:
```
make up -j4
```
The flag `-j PARALLEL` allows to set how many VMs (Makefile targets) will be run at the same time.

### Shutting down the environment
To destroy the Vagrant environment run:
```bash
make clean
make clean-data
```

### Copy local Docker image into VMs
```
make load-image IMG=your_name/your_image_name:your_tag
make load-image IMG=your_name/your_image_name
make load-image IMG=my-private-registry.com/your_name/your_image_name:your_tag
```

### Data inside VM
See the `data/VM_NAME/` directories, where `VM_NAME` is for example `master`.

## Variables
| Variable Name     | Default Value            | Description                                                                                          |
| ----------------- | ------------------------ | ---------------------------------------------------------------------------------------------------- |
| `BOX_IMAGE`       | `centos/7`               | Set the VMs box image to use.                                                                        |
| `DISK_COUNT`      | `1`                      | Set how many additional disks will be added to the VMs.                                              |
| `DISK_SIZE_GB`    | `10` GB                  | Size of additional disks added to the VMs.                                                           |
| `NODE_COUNT`      | `2`                      | How many worker nodes should be spawned.                                                             |
| `MASTER_IP`       | `192.168.26.10`          | The Kubernetes master node IP.                                                                       |
| `NODE_IP_NW`      | `192.168.26.`            | The first three parts of the IPs used for the nodes.                                                 |
| `POD_NW_CIDR`     | `10.244.0.0/16`          | The Pod (container) network CIDR.                                                                    |
| `K8K8S_DASHBOARD` | `false`                  | Install the Kubernetes dashboard addon.                                                              |
| `CLUSTER_NAME`    | `k8s-vagrant-multi-node` | The name of the directory the Makefile is in.                                                        |
| `KUBETOKEN`       | `""` (empty)             | The `kubeadm` "join" token to use. Will be generated automatically using `/dev/urandom/` when empty. |

## Demo
### Start Cluster
[![asciicast](https://asciinema.org/a/186375.png)](https://asciinema.org/a/186375)

### Destroy Cluster
[![asciicast](https://asciinema.org/a/186376.png)](https://asciinema.org/a/186376)

## ToDo
- [ ] Make resources configurable by environment variables
- [ ] Make Kubernetes version selectable through `kubeadm`
