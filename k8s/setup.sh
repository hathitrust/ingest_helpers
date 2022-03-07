#!/bin/bash

KUBERNETES_SERVER=https://macc.kubernetes.hathitrust.org
path=$(dirname $(realpath $0))

if [[ ! -x $path/kubectl ]];
then 
  echo "Download kubectl to $path/kubectl, e.g: "
  echo "  curl -LO https://dl.k8s.io/release/v1.18.0/bin/linux/amd64/kubectl"
  exit 1;
fi

if [[ ! -e $path/k8s-ca.crt ]];
then
  echo "Copy cluster CA cert to $path/k8s-ca.crt"
  exit 1;
fi

if [[ ! -e $path/token ]];
then
  echo "Put token (from service account secret) in $path/token"
  exit 1;
fi

$path/kubectl config set-cluster cluster --certificate-authority $path/k8s-ca.crt --server $KUBERNETES_SERVER
$path/kubectl config set-credentials default --token $(cat $path/token)
$path/kubectl config set-context default --cluster cluster --user default --namespace ingest
$path/kubectl config use-context default
