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

## apply_yaml

With this role you can "kubectl apply" arbitrary yaml files on a host. You also
"kubectl delete" resources defined in those files as well. The important role
parameters are:

* **puppeteers_kubernetes_apply_yaml_src**: location of the yaml file *templates* on the Ansible controller; this should be "." if you use this from within another role
* **puppeteers_kubernetes_apply_yaml_present**: list of yaml files to run "kubectl apply" against
* **puppeteers_kubernetes_apply_yaml_absent**: list of yaml files to run "kubectl delete" against

See [roles/apply_yaml/defaults/main.yml](roles/apply_yaml/defaults/main.yml) to
see what other parameters are available.

For example usage see [roles/ns_with_sa/tasks/main.yml](roles/ns_with_sa/tasks/main.yml).

## ns_with_sa

The *ns_with_sa* role creates the following resources for a given namespace:

* Namespace
* Role
* RoleBinding
* ServiceAccount

The purpose is to set up a namespace which has a ServiceAccount that Ansible
can use, while limiting Ansible's access to just that particular namespace.

Under the hood the *ns_with_sa* role calls the *apply_yaml* role, which in turn
runs raw *kubectl* commands against yaml files in a staging directory.

The only parameter for this role is *ns*, which defines the namespace to create
and configure.

Once this role has been applied, you can generate a short lifespan
ServiceAccount token for later tasks. Example:

```
- name: Get short lifespan ServiceAccount token for the rest of the plays
  ansible.builtin.command:
    cmd: "/usr/local/bin/kubectl create token ansible --duration 15m --namespace my_namespace"
  register: create_token_cmd

- name: Store token as a fact
  ansible.builtin.set_fact:
    api_key: "{{ create_token_cmd.stdout }}"
```

You can then use *api_key* with *kubernetes.core.k8s* or other tasks that
require an API key.

## certificate_manager

This role install [certificate-manager](https://cert-manager.io). The first
part sets up the namespace and create role, role binding and service account
for Ansible. The second part uses a service account token to apply a HelmChart
custom resource definition ([available by default on k3s](https://docs.k3s.io/add-ons/helm).

The relevant parameters are:

* **puppeteers_kubernetes_certificate_manager_k3s_host**: the k3s host that will run certificate-manager
* **puppeteers_kubernetes_certificate_manager_namespace**: namespace to create certificate-manager resources in (default: certificate-manager)
* **puppeteers_kubernetes_certificate_manager_version**: version of certificate-manager to install; default in [roles/certificate_manager/defaults/main.yml](roles/certificate_manager/defaults/main.yml)

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

It creates three volumes:
* **registry-auth**: htpasswd file
* **registry-data**: registry data
* **registry-certs**: self-signed certificates

The container is configured to listen on port 443, which is expose, by default,
as port 8443 on the host.

By default no registry users are created. To be able to access the registry you
need to add some by passing a dictionary with username and password pairs:

    puppeteers_kubernetes_registry_htpasswd_users:
        joe: somepassword
        jane: anotherpassword

This feature has two dependencies:

* Python *passlib* must be installed on the target host; this is handled by the role for Debian-based operating systems only
* *community.general* collection must be installed on the controller

Note that each user account has full push and pull access to the registry.
Therefore we highly recommend limiting access to the repository to only hosts
that need it. This role is primarily intended to be used with minimal k3s
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

Typically you do not need to touch any of the default variables in this role,
except for htpasswd entries.  Nevertheless you can have a look at the
customization options in
[roles/registry/defaults/main.yml](roles/registry/defaults/main.yml). 

# License

Code in this repository is licensed under BSD-2-Clause license. See
[LICENSE](LICENSE) for details.
