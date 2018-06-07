up:
	@echo "Starting Vagrant Kubernetes multi node environment ..."
	vagrant up
	mkdir -p data/.kube
	vagrant ssh master -c 'sudo cat /root/.kube/config' > data/.kube/config
	@echo "Started Vagrant Kubernetes multi node environment."
	@echo "Run 'export KUBECONFIG=\"$(PWD)/data/.kube/config\"' to be able to use 'kubectl' with the environment."

stop:
	vagrant halt -f

clean:
	vagrant halt -f
	vagrant destroy -f

clean-data:
	rm -rf "$(PWD)/data/*"
	rm -rf "$(PWD)/.vagrant/*.vdi"

.PHONY: up clean
