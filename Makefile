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

up:
	@echo "Starting Vagrant Kubernetes multi node environment ..."
	make master &
	make nodes &
	@echo "Waiting for vagrant up to succeed ..."
	wait
	@echo
	@echo "Kubernetes master and nodes are up."
	@echo
	# Copy kubeconfig
	mkdir -p data/.kube
	vagrant ssh master -c 'sudo cat /root/.kube/config' > data/.kube/config
	@echo "Started Vagrant Kubernetes multi node environment."
	@echo "Run 'export KUBECONFIG=\"$(PWD)/data/.kube/config\"' to be able to use 'kubectl' with the environment."

master:
	vagrant up

nodes:
	for i in $(shell seq 1 $(NODE_COUNT)); do make node-$$i &; done

node-%:
	@echo "Starting node $* ..."
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant up
	@echo "Started node $*."

stop:
	vagrant halt -f
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes vagrant halt -f

clean:
	vagrant halt -f
	for i in $(shell seq 1 $(NODE_COUNT)); do VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$$i vagrant halt -f; done
	vagrant destroy -f
	for i in $(shell seq 1 $(NODE_COUNT)); do VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$$i vagrant destroy -f; done

clean-data:
	rm -rf "$(PWD)/data/*"
	rm -rf "$(PWD)/.vagrant/*.vdi"

.PHONY: up master nodes stop clean clean-data
.EXPORT_ALL_VARIABLES:
