# Ansible Collection - puppeteers.kubernetes

An Ansible Collection with roles for managing Kubernetes.

# Roles

## k3s

The *puppeteers.kubernetes.k3s* role installs [k3s](https://k3s.io). The
default staging directory is /root. You can customize it with the
*puppeteers_kubernetes_k3s_staging_directory* variable. 

The role is a thin wrapper around the upstream *install-k3s.sh* script. As
such, it should work on any operating system that the script itself supports.

# License

Code in this repository is licensed under BSD-2-Clause license. See
[LICENSE](LICENSE) for details.
