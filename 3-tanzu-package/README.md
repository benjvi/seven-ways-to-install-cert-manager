
# What

So far, we looked at downloading manifests and helm charts directly. However, in cases where you really don't have any opinion on the implementation of a package, you can just tell the cluster to directly install a particular version of a package. This is possible with helm charts and manifests, but we will look at how this can be done using kapp-controller to install `Tanzu packages`, which are based on the imgpkg format.

# How

Right now, the packages are intended to be installed through the `tanzu` CLI. However, this just a thin facade used to create and apply Kubernetes objects - in particular the `PackageRepository` and `InstalledPackage` kapp-controller CRDs. 

## 1. Repo

To connect the kubernetes cluster to the Tanzu package repository, you would run:

`tanzu package repository install --default`

This is equivalent to applying a `PackageRepository` kubernetes manifest:

`kubectl apply -f tce-package-repo.yml`

(Note, to get this files, you first have to run the `tanzu` CLI command and then export the config)

After running through this, the cluster (via `kapp-controller`) will be connected to the package repository, and you can get a list of available packages by running `tanzu package list` or `kubectl get packages`. Now you can start installing packages.

## 2. Installing Packages

To install a package the normal way, you run: 

`tanzu package install cert-manager.tce.vmware.com --config cert-manager.tce.vmware.com-values.yaml --namespace default`

This always generates an `InstalledPackage` and a `ServiceAccount`. Because we specified `--config` a `Secret` is generated two. So, we can use this `tanzu package install` command to generate manifests that we can apply in a GitOps workflow. `generate-deploy.sh` shows how to do this. 

In this case, we used the package config to specify a custom namespace to deploy into.

# Why

## Pros

- Minimal YAML configuration to manage
- Control over versions
- Parameters available for customization

## Cons

- Very minimal ability to customize packages (by design)
- Minimal visibility of what will be installed 
- More complex to get working with a GitOps workflow