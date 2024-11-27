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
- Optional: Additional disks for LVM local storage 

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

# Post Installation

## Let's Encrypt Cert Manager

In this example we are going to use CloudFlare as DNS provider for Let's Encrypt.

1. Install cert-manager Operator from OperatorHub

- Update channel: stable
- Installation mode: All namespaces on cluster (default)
- Installed Namespace: openshift-operators
- Update approval: Automatic

2. Create Secret with Let's Encrypt account key

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: openshift-operators
type: Opaque
stringData:
  api-token: XXXXXXXXXXXXXXXXXX
```

3. Create ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: openshift-operators
spec:
  acme:
    email: <your-email>
    privateKeySecretRef:
      name: letsencrypt
    server: 'https://acme-v02.api.letsencrypt.org/directory'
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-api-token-secret
              key: api-token
```

## OpenShift Router Certificate

1. Create Ingress Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: default-ingress-tls
  namespace: openshift-ingress
spec:
  secretName: default-ingress-tls
  dnsNames:
    - apps.your-cluster-name.your-domain
    - "*.apps.your-cluster-name.your-domain"
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
    group: cert-manager.io
```

2. Patch Ingress Controller

```bash
oc patch ingresscontroller.operator default --type=merge -p '{"spec":{"defaultCertificate": {"name": "default-ingress-tls"}}}' -n openshift-ingress-operator
```

You should receive `ingresscontroller.operator.openshift.io/default patched` as response. This takes a while now.

## API certificate

We also want to have a valid certificate for the API endpoint.

1. Create API Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-ingress-tls
  namespace: openshift-config
spec:
  secretName: api-ingress-tls
  dnsNames:
    - api.your-cluster-name.your-domain
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
    group: cert-manager.io
```
 
2. Patch API Server Configuration

```bash
oc patch apiserver cluster \
     --type=merge -p \
     '{"spec":{"servingCerts": {"namedCertificates":
     [{"names": ["api.your-cluster-name.your-domain"], 
     "servingCertificate": {"name": "api-ingress-tls"}}]}}}' 
```

You should receive `apiserver.config.openshift.io/cluster patched` as response. This takes a while now.

## LVM Local Storage

1. Install LVM Storage Operator from OperatorHub

- Update channel: stable
- Installation mode: A specific namespace on the cluster
- Installed Namespace: openshift-operators
- Update approval: Automatic

2. Create Storage Cluster

In this case I have added 2 additional disks to the homelab node, 
which are used for LVM local storage. `vdb` is a SSD and `vdc` is a HDD.

The `ssd` device class will be set as default storage class for the cluster.

```yaml
apiVersion: lvm.topolvm.io/v1alpha1
kind: LVMCluster
metadata:
  name: lvm-cluster
  namespace: openshift-storage
spec:
  storage:
    deviceClasses:
      - name: ssd
        default: true
        deviceSelector: 
          paths:
            - /dev/vdb
        thinPoolConfig:
          name: thin-pool-ssd
          overprovisionRatio: 10
          sizePercent: 90
      - name: hdd
        deviceSelector: 
          paths:
            - /dev/vdc
        thinPoolConfig:
          name: thin-pool-hdd
          overprovisionRatio: 10
          sizePercent: 90
```

## Optional: Persistent storage for Monitoring

Once the LVM local storage is configured, you can adjust the storage class for the OpenShift monitoring components.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    prometheusK8s:
      volumeClaimTemplate:
        spec:
          storageClassName: lvms-hdd
          resources:
            requests:
              storage: 40Gi
    alertmanagerMain:
      volumeClaimTemplate:
        spec:
          storageClassName: lvms-hdd
          resources:
            requests:
              storage: 10Gi
```

### Notice

If your disk contains data, partitions or labels, lvm operator will not be able to use it.
Run this on the OpenShift node as `root` to remove all partitions and labels:

```bash
sgdisk -Z /dev/vdX
blkdiscard /dev/vdX
blockdev --rereadpt /dev/vdX
```
