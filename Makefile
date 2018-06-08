MFILECWD = $(shell pwd)

# === BEGIN USER OPTIONS ===
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

CLUSTER_NAME ?= $(shell basename $(MFILECWD))
# === END USER OPTIONS ===

preflight: token ## Gather checks and variables for the the `up` target
	$(eval KUBETOKEN := $(shell cat $(MFILECWD)/.vagrant/KUBETOKEN))

token: ## Generate a kubeadm join token
	@## Kubeadm join token format is: `[a-z0-9]{6}.[a-z0-9]{16}`
	@if [ ! -f $(MFILECWD)/.vagrant/KUBETOKEN ]; then \
		if [ -z "$(KUBETOKEN)" ]; then \
			echo "$(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1).$(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)" > $(MFILECWD)/.vagrant/KUBETOKEN; \
		else \
			echo "$(KUBETOKEN)" > $(MFILECWD)/.vagrant/KUBETOKEN; \
		fi; \
	fi;

up: preflight master nodes ## Start master and nodes

master: ## Start up masters (automatically done by `up` target)
	vagrant up
	make kubectl

kubectl: ## Configure kubeconfig using `kubectl config`
	$(eval CLUSTERCERTSDIR := $(shell mktemp -d))

	vagrant ssh master -c 'sudo cat /etc/kubernetes/pki/ca.crt' \
		> $(CLUSTERCERTSDIR)/ca.crt
	vagrant ssh master -c 'sudo cat /root/.kube/config' \
		> $(CLUSTERCERTSDIR)/config
	@grep -P 'client-certificate-data:' $(CLUSTERCERTSDIR)/config | \
		sed -e 's/^[ \t]*//' | \
		cut -d' ' -f2 | \
		base64 -d -i \
		> $(CLUSTERCERTSDIR)/client-certificate.crt
	@grep -P 'client-key-data:' $(CLUSTERCERTSDIR)/config | \
		sed -e 's/^[ \t]*//' | \
		cut -d' ' -f2 | \
		base64 -d -i \
		> $(CLUSTERCERTSDIR)/client-key.key

	# kubeclt create cluster
	kubectl \
		config set-cluster \
			$(CLUSTER_NAME) \
			--embed-certs=true \
			--server=https://$(MASTER_IP):6443 \
			--certificate-authority=$(CLUSTERCERTSDIR)/ca.crt
	kubectl \
		config set-credentials \
			$(CLUSTER_NAME)-kubernetes-admin \
			--embed-certs=true \
			--username=kubernetes-admin \
			--client-certificate=$(CLUSTERCERTSDIR)/client-certificate.crt \
			--client-key=$(CLUSTERCERTSDIR)/client-key.key
	@rm -rf $(CLUSTERCERTSDIR)

	# kubeclt create context
	kubectl \
		config set-context \
			$(CLUSTER_NAME) \
			--cluster=$(CLUSTER_NAME) \
			--user=$(CLUSTER_NAME)-kubernetes-admin

	# kubectl switch to created context
	kubectl config use-context $(CLUSTER_NAME)
	@echo
	@echo "kubeclt has been configured to use started k8s-vagrant-multi-node Kubernetes cluster"
	@echo "kubectl context name: $(CLUSTER_NAME)"
	@echo

nodes: $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "node-$$i"; done) ## Start up the nodes by utilizing the `node-X` target.

node-%:
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant up

stop: stop-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "stop-node-$$i"; done) ## Stop/Halt all masters and nodes

stop-master:
	vagrant halt -f

stop-node-%:
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant halt -f

clean: clean-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "clean-node-$$i"; done) ## Destroy master and node VMs

clean-master:
	-vagrant destroy -f

clean-node-%:
	-VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant destroy -f node$*

clean-data: ## Remove data (shared folders) and other disks from all VMs
	rm -rf "$(PWD)/data/*"
	rm -rf "$(PWD)/.vagrant/*.vdi"

load-image: load-image-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "load-image-node-$$i"; done) ## Load local Docker image into master and node VMs

load-image-master:
	docker save $(IMG) | vagrant ssh "master" -t -c 'sudo docker load'

load-image-node-%:
	docker save $(IMG) | VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant ssh "node$*" -t -c 'sudo docker load'

status: status-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "status-node-$$i"; done) ## Show status of master and node VMs

status-master:
	@vagrant status | tail -n+3 | head -n-5

status-node-%:
	@VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant status | tail -n+3 | head -n-5

help: ## Show help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.PHONY: preflight up master nodes stop clean clean-data load-image status help
