# Troubleshooting

## When usign Virtualbox as the provider `make up` hangs after it is done

For unknown reasons the makefile is not exiting after it has printed the "cluster creation successful" message.
The issue is being looked into it, till then just do `CTRL+C` to exit the `make up` command.

## "I have a VPN running on my host machine, what should I look out for?"

> **TL;DR** Set the following variables on your `make up` run as follows: `NETWORK_VM_MTU=1350` and `KUBE_NETWORK_MTU=1300`.

Set the `NETWORK_VM_MTU` and `KUBE_NETWORK_MTU` according to the MTU of your VPN interface(s) - "overhead" (`50`).
Using the values in the `TL;DR` should work for "99% percent" of common VPNs.

# Demo

Please note that these terminal recordings are currently outdated.

## Start Cluster

[![asciicast](https://asciinema.org/a/186375.png)](https://asciinema.org/a/186375)

## Destroy Cluster

[![asciicast](https://asciinema.org/a/186376.png)](https://asciinema.org/a/186376)

# Creating an Issue

Please attach the output of the `make versions` command to the issue as is shown in the issue template. This makes debugging easier.
