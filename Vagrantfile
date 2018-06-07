BOX_IMAGE = "centos/7"
SETUP_MASTER = true
SETUP_NODES = true
NODE_COUNT = 3
DISK_COUNT = 1
MASTER_IP = "192.168.26.10"
NODE_IP_NW = "192.168.26."
POD_NW_CIDR = "10.244.0.0/16"
K8S_DASHBOARD = false

# Generate new using steps in README
KUBETOKEN = "b029ee.968a33e8d8e6bb0d"

$baseInstallScript = <<BASEINSTALLSCRIPT
BASEINSTALLSCRIPT

$kubeminionscript = <<MINIONSCRIPT

kubeadm reset

kubeadm join --discovery-token-unsafe-skip-ca-verification --token #{KUBETOKEN} #{MASTER_IP}:6443

MINIONSCRIPT

$kubemasterscript = <<SCRIPT

kubeadm reset
kubeadm init --apiserver-advertise-address=#{MASTER_IP} --pod-network-cidr=#{POD_NW_CIDR} --token #{KUBETOKEN} --token-ttl 0

mkdir -p $HOME/.kube
sudo cp -Rf /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

SCRIPT


$kubedashscript= <<DASHSCRIPT

# Kubernetes Dashboard Setup
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl proxy &

DASHSCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  config.vm.box_check_update = true

  config.vm.provider "virtualbox" do |l|
    l.cpus = 1
    l.memory = "1024"
  end

  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  # config.vm.network "public_network"

  if SETUP_MASTER
    config.vm.define "master" do |subconfig|
      subconfig.vm.hostname = "master"
      subconfig.vm.network :private_network, ip: MASTER_IP
      subconfig.vm.provider :virtualbox do |vb|
        vb.synced_folder "bin/", "/opt/bin"
        vb.synced_folder "data/", "/data"
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize ["modifyvm", :id, "--memory", "2048"]
        vb.customize ["storagectl", :id, "--name", 'SATAController', "--remove"]
        vb.customize ["storagectl", :id, "--name", 'SATAController', "--add", "sata"]
        (1..DISK_COUNT).each do |diskI|
          unless File.exist?(".vagrant/master-disk-#{diskI}.vdi")
            vb.customize ['createhd', '--filename', ".vagrant/master-disk-#{diskI}.vdi", '--variant', 'Standard', '--size', 10 * 1024]
          end
          vb.customize ['storageattach', :id,  '--storagectl', 'SATAController', '--port', diskI-1, '--device', diskI-1, '--type', 'hdd', '--medium', ".vagrant/master-disk-#{diskI}.vdi"]
        end
      end
      subconfig.vm.provision :shell, inline: $kubemasterscript
      if K8S_DASHBOARD
        subconfig.vm.provision :shell, inline: $kubedashscript
        subconfig.vm.network "forwarded_port", guest: 8443, host: 8443
      end
    end
  end

  if SETUP_NODES
    (1..NODE_COUNT).each do |i|
      config.vm.define "node#{i}" do |subconfig|
        subconfig.vm.synced_folder "bin/", "/opt/bin", create: true, owner: "root", group: "root"
        subconfig.vm.synced_folder "data/", "/data", create: true, owner: "root", group: "root"
        subconfig.vm.hostname = "node#{i}"
        subconfig.vm.network :private_network, ip: NODE_IP_NW + "#{i + 10}"
        subconfig.vm.provision :shell, inline: $kubeminionscript
        subconfig.vm.customize ["storagectl", :id, "--name", 'SATAController', "--remove"]
        subconfig.vm.customize ["storagectl", :id, "--name", 'SATAController', "--add", "sata"]
        (1..DISK_COUNT).each do |diskI|
          unless File.exist?(".vagrant/node#{i}-disk-#{diskI}.vdi")
            subconfig.vm.customize ['createhd', '--filename', ".vagrant/node#{i}-disk-#{diskI}.vdi", '--variant', 'Standard', '--size', 10 * 1024]
          end
          subconfig.vm.customize ['storageattach', :id,  '--storagectl', 'SATAController', '--port', diskI-1, '--device', diskI-1, '--type', 'hdd', '--medium', ".vagrant/node#{i}-disk-#{diskI}.vdi"]
        end
      end
    end
  end
end
