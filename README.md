# k8s-vagrant-multi-node
Inspiration to this project was [coolsvap/kubeadm-vagrant](https://github.com/coolsvap/kubeadm-vagrant).

## Prerequisites
* Vagrant (tested with `2.1.1`)
* Vagrant Plugins
    * `vagrant-hostmanager` - Install using `vagrant plugin install vagrant-hostmanager`
* Virtualbox
* `rsync`

## Hardware Requirements
* Master
    * CPU: 2
    * Memory: 2GB
* One Node:
    * CPU: 1
    * Memory: 1GB

## Usage
### Starting the environment
Run `make up` to start up the Vagrant Kubernetes multi node environment.

### Shutting down the environment
Run `make destroy` to destroy the Vagrant environment.

### Data inside VM
See the `data/VM_NAME/` directories, where `VM_NAME` is for example `master`.

## ToDo
- [ ] `vagrant up` master and nodes separately for faster startup
- [ ] Allow env vars to overwrite vars in `Vagrantfile`
