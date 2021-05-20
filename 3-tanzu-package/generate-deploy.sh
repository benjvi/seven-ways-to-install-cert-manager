#!/bin/bash
set -euo pipefail

klean-yaml() {
  yq -y "del(.metadata.generation) | del(.metadata.managedFields) | del(.metadata.creationTimestamp) | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.status)"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# the namespace where the *installedpackage object* will be installed, not cert-manager itself
NAMESPACE="default"
TANZU_PKG="cert-manager.tce.vmware.com"
# need to be connected to a tanzu cluster (kapp-controller installed)
tanzu package install "$TANZU_PKG" --config cert-manager.tce.vmware.com-values.yaml --namespace "$NAMESPACE"
kubectl get secret "$TANZU_PKG-config" -n "$NAMESPACE" -o yaml | klean-yaml > "$SCRIPT_DIR/deploy/Secret.yml"
kubectl get installedpackage "$TANZU_PKG" -n "$NAMESPACE" -o yaml | klean-yaml > "$SCRIPT_DIR/deploy/InstalledPackage.yml"
tanzu package delete "$TANZU_PKG" -n "$NAMESPACE"


