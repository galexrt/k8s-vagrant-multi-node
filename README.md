# k8s-vagrant-multi-node
Inspiration to this project was [coolsvap/kubeadm-vagrant](https://github.com/coolsvap/kubeadm-vagrant).

## Prerequisites
* Vagrant (tested with `2.1.1`)
* Virtualbox
* `rsync`
* `/dev/urandom` when no `KUBETOKEN` is given

## Hardware Requirements
* Master
    * CPU: 2 Cores
    * Memory: 2GB
* 1x Node:
    * CPU: 1 Core
    * Memory: 1GB

These values can currently only be changed by editing `Vagrantfile` and `Vagrantfile_nodes` directly,
but will probably be configurable by environment variables in the future.

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
| Variable Name     | Default Value            | Description                                                                                         |
| ----------------- | ------------------------ | --------------------------------------------------------------------------------------------------- |
| `BOX_IMAGE`       | `centos/7`               | Set the VMs box image to use.                                                                       |
| `DISK_COUNT`      | `1`                      | Set how many additional disks will be added to the VMs.                                             |
| `DISK_SIZE_GB`    | `10` GB                  | Size of additional disks added to the VMs.                                                          |
| `NODE_COUNT`      | `2`                      | How many worker nodes should be spawned.                                                            |
| `MASTER_IP`       | `192.168.26.10`          | The Kubernetes master node IP.                                                                      |
| `NODE_IP_NW`      | `192.168.26.`            | The first three parts of the IPs used for the nodes.                                                |
| `POD_NW_CIDR`     | `10.244.0.0/16`          | The Pod (container) network CIDR.                                                                   |
| `K8K8S_DASHBOARD` | `false`                  | Install the Kubernetes dashboard addon.                                                             |
| `CLUSTER_NAME`    | `k8s-vagrant-multi-node` | The name of the directory the Makefile is in.                                                       |
| `KUBETOKEN`       | `""` (empty)               | The `kubeadm` "join" token to use. Will be generated automatically using `/dev/urandom/ when empty. |

## ToDo
- [ ] Make resources configurable by environment variables
