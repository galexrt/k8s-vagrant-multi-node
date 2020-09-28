# Prerequisites

## Software Requirements

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
> For more information, see the [Variables](#variables) section.

## Hardware Requirements

* Master
  * CPU: 2 Cores (`MASTER_CPUS`)
  * Memory: 2GB (`MASTER_MEMORY_SIZE_GB`)
* 1x Node:
  * CPU: 1 Core (it is recommended to use at least 2 Cores; `NODE_CPUS`)
  * Memory: 2GB (it is recommended to use more than 2GB; `NODE_MEMORY_SIZE_GB`)

These resources can be changed by setting the according variables for the `make up` command, see [Variables](#variables) section.
