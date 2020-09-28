## Usage

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

## make Targets

See [make Targets doc page](make-targets.md) for a full list of all `make` targets (`make help`).
