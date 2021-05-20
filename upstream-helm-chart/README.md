
# What

The cert-manager project provides a helm "chart", retrievable from a helm repository, which packages the Kubernetes manifest files. It parameterizes the manifests and provides some parameters that users can use to customize the installation.

# How

The typical flow would be to use the `helm` CLI to connect to the chart repository and install the chart:
```
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.3.1 \
  --set installCRDs=true
```

Instead, we use `vendir` to download the chart, and the `helm` CLI to template it:

`helm template cert-manager vendor --values values.yaml --namespace cert-manager-chart --create-namespace`

As for the `upstream-manifests`, we run `yshard`, which splits up the manifests into separate files by the Kubernetes reource `kind`.

After this additional step, we can inspect the kubernetes manifests as in the `upstream-manifests` case. If we do a diff between this `upstream-chart/deploy` folder and the `upstream-manifests/deploy` folder, we can see three main differences:
- the helm chart applies additional labels to resources
- we were able to set a different namespace using helm
- the namespace resource is not included in the rendered chart, but it is present in the `upstream-manifests`

# Why

## Pros

 - Some parameters available for customization (we were able to set the namespace)
 - Able to select specific versions for install
 - Able to render to plain manifests, to make use of kubernetes tooling

## Cons

- More complicated install process
- Need to understand the helm templating language
- Still need additional tooling to customize manifests
- No way to set control over a version range, can only fetch latest versions. No advantages over Github releases in this regard
- Not all the customizations we want to make are available, still need to make ad-hoc customizations with kustomize/ytt

## TODOs

- Use kustomize to set labels on everything - [with a transformer](https://patrick-picard.medium.com/kustomization-applying-labels-gotchas-a53f87277661)
