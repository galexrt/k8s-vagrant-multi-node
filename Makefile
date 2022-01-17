# Bash is required as the shell
SHELL := /usr/bin/env bash

# Set Makefile directory in variable for referencing other files
MFILECWD = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# sed 1-liner to reverse the lines in an input stream
REVERSE_LINES=sed -e '1!G;h;$$!d'

VAGRANT ?= vagrant
# Which kubectl to use, default is to use kubectl from `PATH`
KUBECTL ?= kubectl

# === BEGIN USER OPTIONS ===
# Vagrant Provider
VAGRANT_DEFAULT_PROVIDER ?= virtualbox
# Vagrantfile set to use.
BOX_OS ?= fedora
# Vagrant Box image to use.
BOX_IMAGE ?= $(shell grep "^\$$box_image.*=.*'.*'\.freeze" "$(MFILECWD)/vagrantfiles/$(BOX_OS)/common" | cut -d\' -f4)
# Disk setup
DISK_COUNT ?=
DISK_SIZE_GB ?=
# VM Resources
MASTER_CPUS ?=
MASTER_MEMORY_SIZE_GB ?=
NODE_CPUS ?=
NODE_MEMORY_SIZE_GB ?=
NODE_COUNT ?= 2
# Libvirt
LIBVIRT_STORAGE_POOL ?=
# Network
MASTER_IP ?= 192.168.26.10
NODE_IP_NW ?=
POD_NW_CIDR ?=
# Addons
## Kubernetes Dashboard
K8S_DASHBOARD ?=
K8S_DASHBOARD_VERSION ?=
## kube-web-view
KUBE_WEB_VIEW ?=
CLUSTER_NAME ?= $(shell basename $(MFILECWD))
KUBETOKEN ?=
# Kubernetes and kubeadm
# `kubeadm init` flags for master
# NOTE: The `--kubernetes-version` is automatically set if `KUBERNETES_VERSION` is given.
KUBEADM_INIT_FLAGS ?=
# `kubeadm join` flags for nodes
KUBEADM_JOIN_FLAGS ?=
KUBERNETES_VERSION ?=
KUBERNETES_PKG_VERSION_SUFFIX ?=
KUBE_NETWORK ?=
KUBECTL_AUTO_CONF ?= true
USER_SSHPUBKEY ?=
USER_POST_INSTALL_SCRIPT_PATH ?=
HTTP_PROXY ?=
HTTPS_PROXY ?=
HTTP_PROXY_USERNAME ?=
HTTP_PROXY_PASSWORD ?=
NO_PROXY ?=
INSTALL_ADDITIONAL_PACKAGES ?=
PARALLEL_VM_START ?= false
NETWORK_VM_MTU ?=
KUBE_NETWORK_MTU ?=
# === END USER OPTIONS ===

VAGRANT_LOG ?=
VAGRANT_VAGRANTFILE ?= $(MFILECWD)/vagrantfiles/Vagrantfile

preflight: token vagrant-plugins-require ## Run checks and gather variables, used for the the `up` target.
	$(eval KUBETOKEN := $(shell cat $(MFILECWD)/.vagrant/KUBETOKEN))
	$(MAKE) versions

token: ## Generate a kubeadm join token, if needed (token file is `DIRECTORY_OF_MAKEFILE/.vagrant/KUBETOKEN`).
	@## Kubeadm join token format is: `[a-z0-9]{6}.[a-z0-9]{16}`
	@if [ ! -d "$(MFILECWD)/.vagrant" ]; then \
		mkdir -p "$(MFILECWD)/.vagrant"; \
	fi
	@if [ ! -f "$(MFILECWD)/.vagrant/KUBETOKEN" ]; then \
		if [ -z "$(KUBETOKEN)" ]; then \
			if [ -c /dev/urandom ]; then \
				echo "$(shell LC_ALL=C tr -cd 'a-z0-9' < /dev/urandom | fold -w 6 | head -n 1).$(shell LC_ALL=C tr -cd 'a-z0-9' < /dev/urandom | fold -w 16 | head -n 1)" > "$(MFILECWD)/.vagrant/KUBETOKEN"; \
			else \
				echo "$(shell openssl rand -hex 3).$(shell openssl rand -hex 8)" > "$(MFILECWD)/.vagrant/KUBETOKEN"; \
			fi; \
		else \
			echo "$(KUBETOKEN)" > "$(MFILECWD)/.vagrant/KUBETOKEN"; \
		fi; \
	fi

vagrant-plugins-require:
	@if [ "$(BOX_OS)" = "fedora" ]; then \
		$(MAKE) vagrant-plugins; \
	fi

vagrant-plugins: ## Checks that vagrant-reload plugin is installed, if not try to install it
	@if ! $(VAGRANT) plugin list | grep -q vagrant-reload; then \
		echo "vagrant-plugins: vagrant-reload is not installed, will try to install ..."; \
		$(VAGRANT) plugin install vagrant-reload || { echo "vagrant-plugins: failed to install vagrant-reload plugin."; exit 1; }; \
		echo "vagrant-plugins: vagrant-reload plugin has been installed."; \
	else \
		echo "vagrant-plugins: vagrant-reload is already installed."; \
	fi

versions: ## Print the "imporant" tools versions out for easier debugging.
	@echo "=== BEGIN Version Info ==="

	@echo "Repo state: $$(git rev-parse --verify HEAD) (dirty? $$(if git diff --quiet; then echo 'NO'; else echo 'YES'; fi))"

	-@echo "make: $$(command -v make)"
	-@echo "kubectl: $$(command -v kubectl)"
	-@echo "grep: $$(command -v grep)"
	-@echo "cut: $$(command -v cut)"
	-@echo "rsync: $$(command -v rsync)"
	-@echo "openssl: $$(command -v openssl)"
	-@echo "/dev/urandom: $$(if test -c /dev/urandom; then echo OK; else echo 404; fi)"

	-@echo "Vagrant version: $$($(VAGRANT) --version)"
	@echo "=== BEGIN Vagrant Plugins ==="
	-@$(VAGRANT) plugin list
	@echo "=== END Vagrant Plugins ==="
	-@echo "vboxmanage version: $$(vboxmanage --version)"
	-@echo "libvirtd version: $$(libvirtd --version)"

	@echo "=== END Version Info ==="

up: preflight ## Start Kubernetes Vagrant multi-node cluster. Creates, starts and bootsup the master and node VMs.
	$(MAKE) start
	@echo
	$(KUBECTL) get nodes
	@echo
	@echo "Your k8s-vagrant-multi-node Kuberenetes cluster should be ready now."

start: preflight pull
	@# virtualbox: seems to hang the makefile randomly when master and nodes are started at the same time
	@# libvirt: Need to start master and nodes separately due to some weird IP assignment side effects (at least on my machine)
	@# Users can force VMs to be created in parallel by setting `PARALLEL_VM_START=true`
ifeq ($(PARALLEL_VM_START),true)
	$(MAKE) start-master start-nodes
else
	$(MAKE) start-master
	$(MAKE) start-nodes
endif
	@if $(KUBECTL_AUTO_CONF); then \
		$(MAKE) kubectl; \
	else \
		echo "=>> kubectl auto configuration is disabled."; \
		echo "Run '$(MAKE) ssh-master' to connect to the Kubernetes master and then run 'sudo -i' to be able to use 'kubectl' on the cluster."; \
	fi

kubectl: ## Configure kubeconfig context for the cluster using `kubectl config` (automatically done by `up` target).
	$(eval CLUSTERCERTSDIR := $(shell mktemp -d))

	$(VAGRANT) ssh master -c 'sudo cat /etc/kubernetes/pki/ca.crt' \
		> $(CLUSTERCERTSDIR)/ca.crt
	$(VAGRANT) ssh master -c 'sudo grep -P "client-certificate-data:" /root/.kube/config | \
		sed -e "s/^[ \t]*//" | \
		cut -d" " -f2 | \
		base64 -d -i' \
		> $(CLUSTERCERTSDIR)/client-certificate.crt
	$(VAGRANT) ssh master -c 'sudo grep -P "client-key-data:" /root/.kube/config | \
		sed -e "s/^[ \t]*//" | \
		cut -d" " -f2 | \
		base64 -d -i' \
		> $(CLUSTERCERTSDIR)/client-key.key

	# kubectl create cluster
	$(KUBECTL) \
		config set-cluster \
			$(CLUSTER_NAME) \
			--embed-certs=true \
			--server=https://$(MASTER_IP):6443 \
			--certificate-authority=$(CLUSTERCERTSDIR)/ca.crt
	# kubectl create user
	$(KUBECTL) \
		config set-credentials \
			$(CLUSTER_NAME)-kubernetes-admin \
			--embed-certs=true \
			--username=kubernetes-admin \
			--client-certificate=$(CLUSTERCERTSDIR)/client-certificate.crt \
			--client-key=$(CLUSTERCERTSDIR)/client-key.key
	@rm -rf $(CLUSTERCERTSDIR)
	# kubectl create context
	$(KUBECTL) \
		config set-context \
			$(CLUSTER_NAME) \
			--cluster=$(CLUSTER_NAME) \
			--user=$(CLUSTER_NAME)-kubernetes-admin

	# kubectl switch to created context
	$(MAKE) kubectl-use-context
	@echo
	@echo "kubectl has been configured to use started k8s-vagrant-multi-node Kubernetes cluster"
	kubectl config current-context
	@echo

kubectl-use-context: ## Use the created CLUSTER_NAME context using `kubectl config`
	kubectl config use-context $(CLUSTER_NAME)

kubectl-delete: ## Delete the created CLUSTER_NAME context from the kubeconfig (uses kubectl).
	$(eval CLUSTERCERTSDIR := $(shell mktemp -d))
	if (kubectl config get-contexts $(CLUSTER_NAME) > /dev/null 2>&1); then kubectl config delete-context $(CLUSTER_NAME); fi

pull: ## Add and download, or update the box image for the chosen provider on the host.
	echo $(MFILECWD)
	if ! ($(VAGRANT) box list | grep "$(BOX_IMAGE)" | grep -qi "$(VAGRANT_DEFAULT_PROVIDER)"); then \
		$(VAGRANT) \
			box \
			add \
			--provider $(VAGRANT_DEFAULT_PROVIDER) \
			$(BOX_IMAGE); \
	else \
		$(VAGRANT) \
			box \
			update \
			--provider $(VAGRANT_DEFAULT_PROVIDER) \
			--box=$(BOX_IMAGE); \
	fi

start-master: preflight ## Start up master VM (automatically done by `up` target).
	$(VAGRANT) up --provider $(VAGRANT_DEFAULT_PROVIDER)

start-node-%: preflight ## Start node VM, where `%` is the number of the node.
	NODE=$* $(VAGRANT) up --provider $(VAGRANT_DEFAULT_PROVIDER)

start-nodes: preflight $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "start-node-$$i"; done) ## Create and start all node VMs by utilizing the `node-X` target (automatically done by `up` target).

stop: stop-master $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "stop-node-$$i"; done) ## Stop/Halt master and all nodes VMs.

stop-master: ## Stop/Halt the master VM.
	$(VAGRANT) halt -f

stop-node-%: ## Stop/Halt a node VM, where `%` is the number of the node.
	NODE=$* $(VAGRANT) halt -f

stop-nodes: $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "stop-node-$$i"; done) ## Stop/Halt all node VMs.

ssh-master: ## SSH into the master VM.
	$(VAGRANT) ssh

ssh-node-%: ## SSH into a node VM, where `%` is the number of the node.
	NODE=$* $(VAGRANT) ssh

clean: kubectl-delete clean-master $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "clean-node-$$i"; done) ## Destroy master and node VMs, delete data and the kubectl context.
	$(MAKE) clean-data

clean-master: kubectl-delete ## Remove the master VM and the kubectl context.
	-$(VAGRANT) destroy -f

clean-node-%: ## Remove a node VM, where `%` is the number of the node.
	-NODE=$* $(VAGRANT) destroy -f node$*

clean-nodes: $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "clean-node-$$i"; done) ## Remove all node VMs.

clean-data: ## Remove data (shared folders) and disks of all VMs (master and nodes).
	rm -v -rf "$(MFILECWD)/data/"*
	rm -v -rf "$(MFILECWD)/.vagrant/KUBETOKEN"

clean-force: ## Remove all drives which should normally have been removed by the normal clean-master or clean-node-% targets.
	rm -v -rf "$(MFILECWD)/.vagrant/"*.vdi "$(MFILECWD)/.vagrant/"*.img

vagrant-reload: vagrant-reload-master vagrant-reload-nodes ## Run vagrant reload on master and nodes.

vagrant-reload-master: vagrant-plugins ## Run vagrant reload for master VM.
	$(VAGRANT) reload

vagrant-reload-node-%: vagrant-plugins ## Run `vagrant reload` for specific node  VM.
	NODE=$* $(VAGRANT) reload

vagrant-reload-nodes: $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "vagrant-reload-node-$$i"; done) ## Run `vagrant reload` for all node VMs.

load-image: load-image-master $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "load-image-node-$$i"; done) ## Load local/pulled Docker image into master and all node VMs.

load-image-master: ## Load local/pulled image into master VM.
	docker save $(IMG) | $(VAGRANT) ssh "master" -t -c 'sudo docker load'
	@if [ ! -z "$(TAG)" ]; then \
		$(VAGRANT) ssh "master" -t -c 'sudo docker tag $(IMG) $(TAG)'; \
	fi

load-image-node-%: ## Load local/pulled image into node VM, where `%` is the number of the node.
	docker save $(IMG) | NODE=$* $(VAGRANT) ssh "node$*" -t -c 'sudo docker load'
	@if [ ! -z "$(TAG)" ]; then \
		NODE=$* $(VAGRANT) ssh "node$*" -t -c 'sudo docker tag $(IMG) $(TAG)'; \
	fi

load-image-nodes: $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "load-image-node-$$i"; done) ## Load local/pulled Docker image into all node VMs.

ssh-config: ssh-config-master ssh-config-nodes ## Generate SSH config for master and nodes.

ssh-config-master: ## Generate SSH config just for the master.
	@$(VAGRANT) ssh-config --host "master"

ssh-config-nodes: $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "ssh-config-node-$$i"; done) ## Generate SSH config just for the nodes.

ssh-config-node-%: ## Generate SSH config just for the one node number given.
	@NODE=$* $(VAGRANT) ssh-config --host "node$*"

status: status-master $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "status-node-$$i"; done) ## Show status of master and all node VMs.

status-master: ## Show status of the master VM.
	@set -o pipefail; \
		STATUS_OUT="$$($(VAGRANT) status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +6 | $(REVERSE_LINES); \
		else \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +3 | $(REVERSE_LINES); \
		fi | \
			sed '/^$$/d'

status-node-%: ## Show status of a node VM, where `%` is the number of the node.
	@set -o pipefail; \
		STATUS_OUT="$$(NODE=$* $(VAGRANT) status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +6 | $(REVERSE_LINES); \
		else \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +3 | $(REVERSE_LINES); \
		fi | \
			sed '/^$$/d'

status-nodes: $(shell for (( i=1; i<=$(NODE_COUNT); i+=1 )); do echo "status-node-$$i"; done) ## Show status of all node VMs.

tests: ## Run shunit2 tests (`expect` command is required).
	@KUBERNETES_VERSION=$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | sed 's/^v//') \
		bash ./tests/cluster-tests.sh$(if $(TESTS), -- $(TESTS),)

help: ## Show this help menu.
	@echo "Usage: make [TARGET ...]"
	@echo
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.PHONY: help kubectl kubectl-delete preflight token up \
	clean clean-data clean-master clean-nodes \
	load-image load-image-master load-image-nodes \
	ssh-config ssh-config-master ssh-config-nodes \
	ssh-master \
	start-master start-nodes \
	status status-master status-nodes \
	stop stop-master stop-nodes \
	tests \
	vagrant-reload vagrant-reload-master vagrant-reload-nodes \
	vagrant-plugins

.PHONY: docs-serve
docs-serve:
	docker run --net=host --volume "$$(pwd)":"$$(pwd)" --workdir "$$(pwd)" -it squidfunk/mkdocs-material

.PHONY: docs-build
docs-build:
	docker run --net=host --volume "$$(pwd)":"$$(pwd)" --workdir "$$(pwd)" -it squidfunk/mkdocs-material build --clean
