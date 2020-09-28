# Targets

```shell
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
pull                           Add and download, or update the box image for the chosen provider on the host.
ssh-config-master              Generate SSH config just for the master.
ssh-config-node-%              Generate SSH config just for the one node number given.
ssh-config-nodes               Generate SSH config just for the nodes.
ssh-config                     Generate SSH config for master and nodes.
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
tests                          Run shunit2 tests (`expect` command is required).
token                          Generate a kubeadm join token, if needed (token file is `DIRECTORY_OF_MAKEFILE/.vagrant/KUBETOKEN`).
up                             Start Kubernetes Vagrant multi-node cluster. Creates, starts and bootsup the master and node VMs.
vagrant-plugins                Checks that vagrant-reload plugin is installed, if not try to install it
vagrant-reload-master          Run vagrant reload for master VM.
vagrant-reload-nodes           Run `vagrant reload` for all node VMs.
vagrant-reload-node-%          Run `vagrant reload` for specific node  VM.
vagrant-reload                 Run vagrant reload on master and nodes.
versions                       Print the "imporant" tools versions out for easier debugging.
```

Be sure to checkout the [Variables doc page](../configuration.md).
