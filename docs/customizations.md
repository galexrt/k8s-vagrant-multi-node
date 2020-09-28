# Customizations

## SSH Key

Set the `USER_SSHPUBKEY` variable to the path of a SSH public key you want to have added to the `vagrant` user inside the VMs.

**Example**: `USER_SSHPUBKEY=/home/$USER/.ssh/id_rsa.pub`

## Executing Custom Scripts

To execute a custom script after a VM / server has been installed, set the variable `USER_POST_INSTALL_SCRIPT_PATH` to the path of the script.

**Example**: `USER_POST_INSTALL_SCRIPT_PATH=./examples/user_post_install_script.sh`

The script will be copied from the host inside each VM / server.

??? hint
    When the script is executed on the master, `kubectl` should be accessible but the Nodes might not exist yet.

**Example Output**:
```
[...]
==> master: Running provisioner: shell...
    master: Running: inline script
    master: Execute userPostInstallScript
    master: I am a script that runs after the installation of Kubernetes has been done on each server.
[...]
```

## Operating System (OS) used for the VMs

See [VM OS Selection doc page](vm-os-selection.md).
