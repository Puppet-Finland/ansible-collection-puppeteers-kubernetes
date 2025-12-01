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
process](https://olm.operatorframework.io/docs/getting-started). It does nothing if
OLM is already installed.

You can optionally modify the following variables:

* **puppeteers_kubernetes_olm_staging_directory**: directory to put all downloaded files into
* **puppeteers_kubernetes_olm_base_url**: base URL for operator-sdk
* **puppeteers_kubernetes_olm_version**: version of operator-sdk (part of the download URL)
* **puppeteers_kubernetes_olm_filename**: operator-sdk filename (part of the download URL)

See [roles/olm/defaults/main.yml](roles/olm/defaults/main.yml) for details and
default values.

## registry

This role installs the official [Docker
registry](https://hub.docker.com/_/registry) on a host. It is intended to run
outside of Kubernetes, e.g. on a build host. It depends on Podman and Podman
Quadlets:

* https://www.redhat.com/en/blog/quadlet-podman
* https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html

Basically the container and its dependencies run as systemd units. The service
that manages the registry is rather intuitively called "registry.service".

It creates two volumes (*registry-data* and *registry-certs*) and populates the
latter with self-signed certificates. The container is configured to listen on
port 443, which is expose, by default, as port 8443 on the host.

The setup is insecure in the sense that there is no authentication for
accessing the repository. We highly recommend limiting access to the repository
to only hosts that need it. As it stands, it is mainly useful for minimal k3s
environments where a container registry is needed, but spinning up something
like Quay.io (and its fatty dependency, Noobaa), is an overkill.

To push to the registry with podman you need to add a registry configuration,
e.g.  */etc/containers/registries.conf.d/900-local-registry.conf* with contents
like this:

```
[[registry]]
prefix = "registry.example.com:8443"
insecure = false
location = "registry.example.com:8443"
```

The `insecure = false` setting ensures that podman does not choke on the
self-signed certificate. Once all of this is set up, you can push to the
registry, inspect its contents, etc. as usual. For example:

    $ podman push docker.io/library/nginx docker://registry.example.com:8443/nginx
    $ skopeo inspect docker://builder.beta.kaiwoo.vpn:8443/nginx
    $ skopeo delete docker://builder.beta.kaiwoo.vpn:8443/nginx

Typically you do not need to touch any of the default variables in this role.
Nevertheless you can have a look at the customization options in
[roles/registry/defaults/main.yml](roles/registry/defaults/main.yml). 

# License

Code in this repository is licensed under BSD-2-Clause license. See
[LICENSE](LICENSE) for details.
