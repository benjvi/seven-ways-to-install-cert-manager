#!/bin/bash
set -euo pipefail

klean-yaml() {
  yq -y "del(.metadata.generation) | del(.metadata.managedFields) | del(.metadata.creationTimestamp) | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.status) | del(.metadata.annotations[\"kubectl.kubernetes.io/last-applied-configuration\"])"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# the namespace where the *app object* will be installed, not cert-manager itself
NAMESPACE="default"
TANZU_PKG="cert-manager.tce.vmware.com"
# need to be connected to a tanzu cluster (kapp-controller installed)
tanzu package install "$TANZU_PKG" --config cert-manager.tce.vmware.com-values.yaml --namespace "$NAMESPACE"
kubectl get secret "$TANZU_PKG-config" -n "$NAMESPACE" -o yaml | klean-yaml > "$SCRIPT_DIR/deploy/Secret.yml"
kubectl get sa "$TANZU_PKG-extension-sa" -n "$NAMESPACE" -o yaml | klean-yaml | yq -y "del(.secrets)" > "$SCRIPT_DIR/deploy/ServiceAccount.yml"
kubectl get app "$TANZU_PKG" -n "$NAMESPACE" -o yaml | klean-yaml | yq -y "del(.metadata.ownerReferences)" > /tmp/App.yml
tanzu package delete "$TANZU_PKG" -n "$NAMESPACE"

kubectl create cm cert-manager-app-custom-ytt-overlay --namespace "$NAMESPACE" --from-file "$SCRIPT_DIR/ytt-overlay-add-label.yml" --dry-run=client -o yaml > "$SCRIPT_DIR/deploy/ConfigMap.yml"

ytt -f /tmp/App.yml -f app-overlay-add-ytt-step.yml > "$SCRIPT_DIR/deploy/App.yml"
