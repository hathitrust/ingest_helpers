#!/bin/bash

export kubeexec=$(dirname $(realpath -- "$0"))/../k8s/kubeexec

function pathify_args {
  for arg in "$@"; do if [[ -e "$arg" ]]; then realpath "$arg"; else printf -- "$arg\n"; fi; done
}

