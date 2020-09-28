# Different OS / Vagrantfiles

There are multiple sets of Vagrantfiles available (see [`vagrantfiles/`](/vagrantfiles/)) which can be used to use a different OS for the Kubernetes environment.

List of currently available Vagrantfile sets:

| Name      | Container Runtime                           | OS Version   | Special Notes                                                                                                            |
| --------- | ------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------ |
| `centos7` | [Docker/Moby](https://github.com/moby/moby) | CentOS 7     | N/A                                                                                                                      |
| `centos8` | [Docker/Moby](https://github.com/moby/moby) | CentOS 8     | `KUBE_NETWORK=calico` is forced, due to issues under CentOS 8 regarding `iptables`.                                      |
| `centos`  | [Docker/Moby](https://github.com/moby/moby) | CentOS 7     | Use `centos7` in favor of this, as this "target" might be changed to `centos8` in a future release.                      |
| `fedora`  | [Docker/Moby](https://github.com/moby/moby) | Fedora 32    | N/A                                                                                                                      |
| `ubuntu`  | [Docker/Moby](https://github.com/moby/moby) | Ubuntu 18.04 | `KUBE_NETWORK=canal` is forced, due to issues under Ubuntu. Additionally Google DNS Servers are used as the nameservers. |

To use a different set than the default `fedora` one's, add `BOX_OS=__NAME__` (where `__NAME__` is, e.g., `fedora`).
