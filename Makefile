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

preflight: token ## Run checks and gather variables, used for the the `up` target.
	$(eval KUBETOKEN := $(shell cat $(MFILECWD)/.vagrant/KUBETOKEN))

token: ## Generate a kubeadm join token, if needed (token file is `DIRECTORY_OF_MAKEFILE/.vagrant/KUBETOKEN`).
	@## Kubeadm join token format is: `[a-z0-9]{6}.[a-z0-9]{16}`
	@if [ ! -f "$(MFILECWD)/.vagrant/KUBETOKEN" ]; then \
		if [ -z "$(KUBETOKEN)" ]; then \
			echo "$(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1).$(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)" > $(MFILECWD)/.vagrant/KUBETOKEN; \
		else \
			echo "$(KUBETOKEN)" > "$(MFILECWD)/.vagrant/KUBETOKEN"; \
		fi; \
	fi

up: preflight start-master start-nodes ## Start Kubernetes Vagrant multi-node cluster. Creates, starts and bootsup the master and node VMs.
	@make kubectl

kubectl: ## Configure kubeconfig context for the cluster using `kubectl config` (automatically done by `up` target).
	$(eval CLUSTERCERTSDIR := $(shell mktemp -d))

	vagrant ssh master -c 'sudo cat /etc/kubernetes/pki/ca.crt' \
		> $(CLUSTERCERTSDIR)/ca.crt
	vagrant ssh master -c 'sudo grep -P "client-certificate-data:" /root/.kube/config | \
		sed -e "s/^[ \t]*//" | \
		cut -d" " -f2 | \
		base64 -d -i' \
		> $(CLUSTERCERTSDIR)/client-certificate.crt
	vagrant ssh master -c 'sudo grep -P "client-key-data:" /root/.kube/config | \
		sed -e "s/^[ \t]*//" | \
		cut -d" " -f2 | \
		base64 -d -i' \
		> $(CLUSTERCERTSDIR)/client-key.key

	# kubeclt create cluster
	kubectl \
		config set-cluster \
			$(CLUSTER_NAME) \
			--embed-certs=true \
			--server=https://$(MASTER_IP):6443 \
			--certificate-authority=$(CLUSTERCERTSDIR)/ca.crt
	# kubectl create user
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

start-master: ## Start up master VM (automatically done by `up` target).
	vagrant up

start-nodes: $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "start-node-$$i"; done) ## Create and start all node VMs by utilizing the `node-X` target (automatically done by `up` target).

start-node-%: ## Start node VM, where `%` is the number of the node.
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant up

stop: stop-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "stop-node-$$i"; done) ## Stop/Halt master and all nodes VMs.

stop-master: ## Stop/Halt the master VM.
	vagrant halt -f

stop-node-%: ## Stop/Halt a node VM, where `%` is the number of the node.
	VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant halt -f

stop-nodes: $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "stop-node-$$i"; done) ## Stop/Halt all node VMs.

clean: clean-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "clean-node-$$i"; done) clean-data ## Destroy master and node VMs, and delete data.

clean-master: ## Remove the master VM.
	-vagrant destroy -f

clean-node-%: ## Remove a node VM, where `%` is the number of the node.
	-VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant destroy -f node$*

clean-nodes: $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "clean-node-$$i"; done) ## Remove all node VMs.

clean-data: ## Remove data (shared folders) and disks of all VMs (master and nodes).
	rm -rf "$(PWD)/data/*"
	rm -rf "$(PWD)/.vagrant/*.vdi"

load-image: load-image-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "load-image-node-$$i"; done) ## Load local/pulled Docker image into master and all node VMs.

load-image-master: ## Load local/pulled image into master VM.
	docker save $(IMG) | vagrant ssh "master" -t -c 'sudo docker load'

load-image-node-%: ## Load local/pulled image into node VM, where `%` is the number of the node.
	docker save $(IMG) | VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant ssh "node$*" -t -c 'sudo docker load'

load-image-nodes: $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "load-image-node-$$i"; done) ## Load local/pulled Docker image into all node VMs.

status: status-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "status-node-$$i"; done) ## Show status of master and all node VMs.

status-master: ## Show status of the master VM.
	@STATUS_OUT="$$(vagrant status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | head -n-5; \
		else \
			echo "$$STATUS_OUT" | head -n-2; \
		fi
status-node-%: ## Show status of a node VM, where `%` is the number of the node.
	@STATUS_OUT="$$(VAGRANT_VAGRANTFILE=Vagrantfile_nodes NODE=$* vagrant status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | head -n-5; \
		else \
			echo "$$STATUS_OUT" | head -n-2; \
		fi

status-nodes: $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "status-node-$$i"; done) ## Show status of all node VMs.

help: ## Show this help menu.
	@grep -E '^[a-zA-Z_-%]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.PHONY: clean clean-data clean-master clean-nodes help kubectl load-image \
	load-image-master load-image-nodes preflight start-master start-nodes \
	status-master status-nodes status stop-master stop-nodes stop token up
