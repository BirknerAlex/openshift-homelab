#!/bin/bash

if [[ ! -f .env ]]; then
    touch .env
fi

mkdir -p $(pwd)/output

docker run --platform linux/amd64 \
  -ti --env-file .env --rm --privileged \
  -v $(pwd)/output:/output:z \
  --name openshift-homelab tyrola/openshift-homelab:latest "$@"

export KUBECONFIG=output/auth/kubeconfig
