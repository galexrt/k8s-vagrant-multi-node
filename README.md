# k8s-vagrant-multi-node
Inspiration to this project was [coolsvap/kubeadm-vagrant](https://github.com/coolsvap/kubeadm-vagrant).

## Prerequisites
* Vagrant (tested with `2.1.1`)
* Vagrant Plugins
    * `vagrant-hostmanager` - Install using `vagrant plugin install vagrant-hostmanager`

## Usage
### Starting the environment
Run `make up` to start up the Vagrant Kubernetes multi node environment.

### Shutting down the environment
Run `make destroy` to destroy the Vagrant environment.
