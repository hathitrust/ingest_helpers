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
  echo "A user with appropriate permissions needs to run:" 
  echo "kubectl -n ingest create token ingest-prep --duration=REASONABLY_LARGE_NUMBER_OF_SECONDs"
  echo "Put the token (from service account secret) in $path/token"
  exit 1;
fi

$path/kubectl config set-cluster cluster --certificate-authority $path/k8s-ca.crt --server $KUBERNETES_SERVER
$path/kubectl config set-credentials ingest-prep --token $(cat $path/token)
$path/kubectl config set-context default --cluster cluster --user ingest-prep --namespace ingest
$path/kubectl config use-context default

rm $path/token
