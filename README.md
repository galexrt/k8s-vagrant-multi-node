# k8s-vagrant-multi-node
Inspiration to this project was [coolsvap/kubeadm-vagrant](https://github.com/coolsvap/kubeadm-vagrant).

## Prerequisites
* Vagrant (tested with `2.1.1`)
* Virtualbox
* `rsync`

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
TODO

## ToDo
- [ ] Make resources configurable by environment variables
