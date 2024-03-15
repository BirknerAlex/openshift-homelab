# openshift-homelab

This project helps you to create an OpenShift single node cluster iso file for your homelab.

### Prerequisites

- Docker installed on your local machine to create the OpenShift cluster iso file
- DHCP running on your local network, which is required for the OpenShift cluster to work
- DNS running on your local network, which is required for the OpenShift cluster to work

### OpenShift Hardware Requirements

- 8 vCPU cores
- 32GB of RAM
- 120GB of disk space

# Usage

1. Create .env file with the following content and adjust the values to your environment:

```bash
# Your SSH public key, which is used to access the OpenShift cluster with the core user via SSH
HOMELAB_SSH_KEY=your-ssh-public-key
# Your Red Hat pull secret, which is used to pull the OpenShift images
HOMELAB_PULL_SECRET=your-pull-secret
# Your domain, which is used to create the DNS records for the OpenShift cluster
HOMELAB_CLUSTER_DOMAIN=your-domain
# Your cluster name, which is used to create the DNS records for the OpenShift cluster
HOMELAB_CLUSTER_NAME=your-cluster-name
# Your network CIDR, which is used to create the DHCP configuration for the OpenShift cluster,
# Ensure that the network CIDR that is used on your homelab DHCP server.
HOMELAB_CIDR=192.168.1.0/24
# THe path to the disk, which is used to install the OpenShift cluster.
HOMELAB_INSTALL_DISK=/dev/vda
```

2. Run the following Docker container to create the OpenShift cluster iso file:

```bash
curl -L https://raw.githubusercontent.com/BirknerAlex/openshift-homelab/main/bootstrap.sh | bash 
```

3. Create the DNS records for the OpenShift cluster. The following DNS records are required:

```
api.your-cluster-name.your-domain
api-int.your-cluster-name.your-domain
*.apps.your-cluster-name.your-domain
```

4. Ensure static IP DHCP configuration for your OpenShift cluster
5. Boot homelab node with the created iso file, ensure DNS and DHCP are configured correctly
6. Access the OpenShift cluster with the web console, the installation can take a while. A loooong while

> **Note for germans**: The installation can take a loooong while. A loooong while. #Neuland

# Persistent Storage

# TODO: Add persistent storage documentation