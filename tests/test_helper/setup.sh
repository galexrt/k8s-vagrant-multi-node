#!/bin/bash

set -x

if command -v vagrant; then
    echo "Vagrant already installed. Exit 0"
    exit 0
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR" || { echo "Unable to cd to $DIR dir"; exit 1; }

mkdir -p .test_files/
cd .test_files/ || { echo "Unable to cd to .test_files/ dir"; exit 1; }

VAGRANT_DEFAULT_PROVIDER="${VAGRANT_DEFAULT_PROVIDER:-libvirt}"
VAGRANT_DEFAULT_PROVIDER="$(echo "${VAGRANT_DEFAULT_PROVIDER}" | tr '[:upper:]' '[:lower:]')"

VAGRANT_VERSION="${VAGRANT_VERSION:-2.2.9}"
VIRTUALBOX_VERSION="${VIRTUALBOX_VERSION:-6.0}"

echo "Installing Vagrant $VAGRANT_VERSION ..."
if [ ! -f "vagrant_${VAGRANT_VERSION}_x86_64.deb" ]; then
    curl -Os "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb"
    curl -Os "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_SHA256SUMS"
    curl -Os "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_SHA256SUMS.sig"
    gpg --receive-key 51852D87348FFC4C
    gpg --verify "vagrant_${VAGRANT_VERSION}_SHA256SUMS.sig" "vagrant_${VAGRANT_VERSION}_SHA256SUMS"
    sha256sum -c "vagrant_${VAGRANT_VERSION}_SHA256SUMS" 2>&1 | grep OK
fi
sudo apt-get update
sudo apt-get install -y bridge-utils dnsmasq-base ebtables
sudo dpkg -i "vagrant_${VAGRANT_VERSION}_x86_64.deb"

echo "Installed Vagrant ${VAGRANT_VERSION}."
vagrant version

case "${VAGRANT_DEFAULT_PROVIDER}" in
    libvirt)
        echo "Installing libvirt"
        sudo apt-get install -y libvirt-bin libvirt-dev qemu-kvm qemu-utils ruby-dev
        sudo vagrant plugin install vagrant-libvirt
        sudo usermod -aG libvirt "$(whoami)"
        sudo usermod -aG libvirt-qemu "$(whoami)"
        echo "Installed libvirt"
    ;;
    virtualbox)
        echo "Installing virtualbox"
        wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
        sudo sh -c "echo deb https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib >> /etc/apt/sources.list"
        sudo apt-get update
        sudo apt-get install -yq build-essential gcc make "linux-headers-$(uname -r)" "virtualbox-${VIRTUALBOX_VERSION}"
        sudo usermod -aG vboxusers "$(whoami)"
        echo "Installed virtualbox"
    ;;
    *)
        echo "Unknown VAGRANT_DEFAULT_PROVIDER (value: ${VAGRANT_DEFAULT_PROVIDER}) given. Continuing for now"
    ;;
esac

echo "Installing kubectl"
KUBERNETES_VERSION="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
curl -Lo "kubectl-${KUBERNETES_VERSION}" "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl"
chmod +x "kubectl-${KUBERNETES_VERSION}"
sudo cp "kubectl-${KUBERNETES_VERSION}" /usr/local/bin/kubectl
echo "Installed kubectl ${KUBERNETES_VERSION}"
