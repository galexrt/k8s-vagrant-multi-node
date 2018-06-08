# Box setup
BOX_IMAGE = ENV["BOX_IMAGE"] || 'centos/7'.freeze
# Disk setup
DISK_COUNT = ENV["DISK_COUNT"].to_i || 2
DISK_SIZE_GB = ENV["DISK_SIZE_GB"].to_i || 10
# Network
MASTER_IP = ENV["MASTER_IP"] || '192.168.26.10'.freeze
POD_NW_CIDR = ENV["POD_NW_CIDR"] || '10.244.0.0/16'.freeze
# Addons
K8S_DASHBOARD = false

# Generate new using steps in README
KUBETOKEN = ENV["KUBETOKEN"] || 'b029ee.968a33e8d8e6bb0d'.freeze

$baseInstallScript = <<BASEINSTALLSCRIPT

set -x
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y net-tools screen tree telnet kubelet kubeadm docker rsync --nogpgcheck
systemctl enable kubelet && systemctl start kubelet
systemctl enable docker && systemctl start docker

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=enforcing/g' /etc/selinux/config
swapoff -a
sed -i '/swap/s/^/#/g' /etc/fstab
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
BASEINSTALLSCRIPT

$kubeMasterScript = <<SCRIPT

set -x
kubeadm reset
kubeadm init --apiserver-advertise-address=#{MASTER_IP} --pod-network-cidr=#{POD_NW_CIDR} --token #{KUBETOKEN} --token-ttl 0

mkdir -p $HOME/.kube
sudo cp -Rf /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
SCRIPT

# Addons
$kubeDashScript = <<DASHSCRIPT

# Kubernetes Dashboard Setup
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl proxy &
DASHSCRIPT

Vagrant.configure('2') do |config|
    config.vm.box = BOX_IMAGE
    config.vm.box_check_update = true

    config.vm.provider 'virtualbox' do |l|
        l.cpus = 1
        l.memory = '1024'
    end

    config.vm.define 'master' do |subconfig|
        subconfig.vm.hostname = 'master'
        subconfig.vm.network :private_network, ip: MASTER_IP
        subconfig.vm.provider :virtualbox do |vb|
            # VM Resources
            vb.customize ['modifyvm', :id, '--cpus', '2']
            vb.customize ['modifyvm', :id, '--memory', '2048']
            # Storage configuration
            if File.exist?('.vagrant/master-disk-1.vdi')
                vb.customize ['storagectl', :id, '--name', 'SATAController', '--remove']
           end
            vb.customize ['storagectl', :id, '--name', 'SATAController', '--add', 'sata']
            (1..DISK_COUNT.to_i).each do |diskI|
                unless File.exist?(".vagrant/master-disk-#{diskI}.vdi")
                    vb.customize ['createhd', '--filename', ".vagrant/master-disk-#{diskI}.vdi", '--variant', 'Standard', '--size', DISK_SIZE_GB * 1024]
                end
                vb.customize ['storageattach', :id, '--storagectl', 'SATAController', '--port', diskI - 1, '--device', diskI - 1, '--type', 'hdd', '--medium', ".vagrant/master-disk-#{diskI}.vdi"]
            end
        end
        subconfig.vm.synced_folder 'data/master/', '/data', type: 'rsync',
                                                            create: true, owner: 'root', group: 'root',
                                                            rsync__args: ["--rsync-path='sudo rsync'", '--archive', '--delete', '-z']
        # Provision
        subconfig.vm.provision :shell, inline: $baseInstallScript
        subconfig.vm.provision :shell, inline: $kubeMasterScript
        # Addons
        if K8S_DASHBOARD.to_s
            subconfig.vm.provision :shell, inline: $kubeDashScript
            subconfig.vm.network 'forwarded_port', guest: 8443, host: 8443
        end
    end
end
