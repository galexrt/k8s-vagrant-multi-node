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

CLUSTER_NAME ?= $(shell basename $(CURDIR))

KUBETOKEN ?= 'b029ee.968a33e8d8e6bb0d'

up: master nodes

master:
	vagrant up

	CLUSTERCERTSDIR := $(shell mktemp -d)
	vagrant ssh master -c 'sudo cat /root/.kube/config' > $(CLUSTERCERTSDIR)/config
	grep -oP 'client-certificate-data: (.+)' .kube/config | cut -d' ' -f2 > $(CLUSTERCERTSDIR)/client-certificate.crt
	grep -oP 'client-key-data: (.+)' .kube/config | cut -d' ' -f2 > $(CLUSTERCERTSDIR)/client-key.crt
	vagrant ssh master -c 'sudo cat /etc/kubernetes/pki/ca.crt' > $(CLUSTERCERTSDIR)/ca.crt

	# kubeclt create cluster
	kubectl \
		config set-cluster \
			$(CLUSTER_NAME) \
			--embed-certs=true \
			--server=$(MASTER_IP) \
			--certificate-authority=$(CLUSTERCERTSDIR)/ca.crt
	kubectl \
		config set-credentials \
			$(CLUSTER_NAME)-kubernetes-admin
			--embed-certs=true \
			--username=kubernetes-admin
			--client-certificate=$(CLUSTERCERTSDIR)/client-certificate.crt \
			--client-key=$(CLUSTERCERTSDIR)/client-key.crt
	rm -rf $(CLUSTERCERTSDIR)

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

load-image: load-image-master $(shell for i in $(shell seq 1 $(NODE_COUNT)); do echo "load-image-node-$$i"; done)

load-image-master:
	docker save $(IMG) | vagrant ssh "master" -t -c 'sudo docker load'

load-image-node-%:
	docker save $(IMG) | NODE=$* VAGRANT_VAGRANTFILE=Vagrantfile_nodes vagrant ssh "node$*" -t -c 'sudo docker load'

.PHONY: up master nodes stop clean clean-master clean-data load-image
.EXPORT_ALL_VARIABLES:
