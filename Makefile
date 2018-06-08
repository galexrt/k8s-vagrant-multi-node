# Box setup
BOX_IMAGE ?= centos/7
# Disk setup
DISK_COUNT ?= 1
DISK_SIZE_GB ?= 10

NODE_COUNT ?= 2
# Network
MASTER_IP ?= 192.168.26.10
NODE_IP_NW ?= 192.168.26.
POD_NW_CIDR ?= 10.244.0.0/16

# Addons
K8S_DASHBOARD ?= false

KUBETOKEN ?= 'b029ee.968a33e8d8e6bb0d'

up: master nodes
	# Copy kubeconfig
	mkdir -p data/.kube
	vagrant ssh master -c 'sudo cat /root/.kube/config' > data/.kube/config

master:
	vagrant up

nodes: $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "node-$$i"; done)

node-%:
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant up

stop:
	vagrant halt -f
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes vagrant halt -f

clean: clean-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "clean-node-$$i"; done)

clean-master:
	-vagrant destroy -f

clean-node-%:
	-VAGRANT_VAGRANTFILE=Vagrantfile_nodes vagrant destroy -f node$*

clean-data:
	rm -rf "$(PWD)/data/*"
	rm -rf "$(PWD)/.vagrant/*.vdi"

.PHONY: up master nodes stop clean clean-master clean-data
.EXPORT_ALL_VARIABLES:
