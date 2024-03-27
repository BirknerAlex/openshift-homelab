FROM fedora:39

ENV OCP_VERSION=stable-4.13
ENV OCP_ARCH=x86_64

COPY /root /

RUN dnf install -y curl coreos-installer && \
    dnf upgrade -y && \
    dnf clean all

ENV PATH=$PATH:/usr/local/bin/

RUN curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/openshift-client-linux.tar.gz \
    -o oc.tar.gz && \
    tar zxf oc.tar.gz && \
    mv oc /usr/local/bin/ && \
    rm -f oc.tar.gz && \
    chmod +x /usr/local/bin/oc

RUN curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/openshift-install-linux.tar.gz \
    -o openshift-install-linux.tar.gz && \
    tar zxf openshift-install-linux.tar.gz && \
    mv openshift-install /usr/local/bin/ && \
    rm -f openshift-install-linux.tar.gz && \
    chmod +x /usr/local/bin/openshift-install

WORKDIR /opt/

RUN curl -k $(/usr/local/bin/openshift-install coreos print-stream-json | grep location | grep $OCP_ARCH | grep iso | cut -d\" -f4) -o /opt/rhcos-live.x86_64.iso

ENV HOMELAB_DEBUG="false"
ENV HOMELAB_PULL_SECRET=""
ENV HOMELAB_SSH_KEY=""
ENV HOMELAB_CIDR=""
ENV HOMELAB_INSTALL_DISK=""
ENV HOMELAB_CLUSTER_NAME="homelab"
ENV HOMELAB_CLUSTER_DOMAIN="homelab.local"

VOLUME ["/output"]

CMD "/usr/bin/run-container"
