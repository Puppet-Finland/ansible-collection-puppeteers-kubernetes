# Ansible Collection - puppeteers.kubernetes

An Ansible Collection with roles for managing Kubernetes.

# Roles

## k3s

The *puppeteers.kubernetes.k3s* role installs [k3s](https://k3s.io). The
default staging directory is /root. You can customize it with the
*puppeteers_kubernetes_k3s_staging_directory* variable. 

The role is a thin wrapper around the upstream *install-k3s.sh* script. As
such, it should work on any operating system that the script itself supports.

Optional role variables:
* **puppeteers_kubernetes_k3s_staging_directory**: staging directory for the files this role needs for installing K3S. Defaults to a subdirectory under /root.
* **puppeteers_kubernetes_k3s_disable_conflicting_services**: whether to automatically disable conflicting services (firewalld, nm-cloud-setup). Defaults to *false*. 

## aws_on_k3s

The *puppeteers.kubernetes.awx_on_k3s* role Installs AWX (formerly known as
Ansible Tower) on k3s. Uses the [AWX
Operator](https://github.com/kurokobo/awx-on-k3s) from kurokobo. Currently only
supports AWX version 2.19.1. Creates a self-signed certificate on the fly during installation.

Mandatory role variables:
* **puppeteers_kubernetes_awx_on_k3s_awx_hostname**: fully-qualified hostname for the AWX instance. Must match the hostname in the URL used to access AWX. For example, if you wish AWX to be accessible through https://awx.example.com you should set this to *awx.example.com*.
* **puppeteers_kubernetes_awx_on_k3s_awx_admin_password**: password for the AWX "admin" user.
* **puppeteers_kubernetes_awx_on_k3s_postgresql_password**: password for the postgresql "awx" user.

Optional role  variables:
* **puppeteers_kubernetes_awx_on_k3s_awx_version**: defaults to 2.19.1. As new versions are released new template files (awx.yaml and kustomization.yaml) need to be added to this role.
* **puppeteers_kubernetes_awx_on_k3s_staging_directory**: staging directory for all the files this role needs for installing AWX on K3S. Defaults to a subdirectory under /root.

## olm

This role installs Operator Lifecycle Manager with operator-sdk. It essentially
replicates the [manual installation
process](https://olm.operatorframework.io/docs/getting-started). You can
optionally modify the following variables:

* **puppeteers_kubernetes_olm_staging_directory**: directory to put all downloaded files into
* **puppeteers_kubernetes_olm_base_url**: base URL for operator-sdk
* **puppeteers_kubernetes_olm_version**: version of operator-sdk (part of the download URL)
* **puppeteers_kubernetes_olm_filename**: operator-sdk filename (part of the download URL)

See [roles/olm/defaults/main.yml](roles/olm/defaults/main.yml) for details and
default values.

# License

Code in this repository is licensed under BSD-2-Clause license. See
[LICENSE](LICENSE) for details.
