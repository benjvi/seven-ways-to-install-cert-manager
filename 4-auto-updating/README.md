
# What

Until now, we only looked at installing specific versions of a package. However, typically, we want to define some sort of process for regularly applying security and product updates. This can be done manually, but generally works better when automated. Although Tanzu packages don't suggest an automated upgrade workflow at the time of writing, the capabilities are already present in the `kapp-controller`, and we will see what possibilities they offer. 

# Option A : `InstalledPackage` version constraints (less safe) 

## How

As in `3-tanzu-package`, we will create manifests for the Tanzu package installation. This time we export those manifests to `vendor` as we want to make some modifications. 

Inspecting the `InstalledPackage`, you will find a field `spec.packageRef.versionSelection.constraints`. By default, this will be set to a specific version, like `1.10.0-vmware0`.

However, this can also be set to a version range, so if we change this to `>= 1.10.0-vmware0` then the `kapp-controller` will automatically deploy a later package if one becomes available, as the `kapp-controller` is continuously reconciling the state of the `InstalledPackage` with the state of the installed components.

We set up a `kustomization.yaml` here to add the necessary additions to the version field, then run kustomize just once to produce the `InstalledPackage` manifest that will subscribe to all future package updates:

`kustomize build | yshard -g ".kind" -o deploy`

## Why

In this way, its possible to tell a cluster to stay on the latest version of a component, or to always take the latest security updates but not automatically update to a new major version of a package (by setting a less than version constraint). The version constraint uses [this library](https://github.com/blang/semver) so there are lots of possibilities for setting version ranges.

However, there is some residual risk to setting version ranges to be evaluated at install-time. In rare cases, even security patches can cause regressions. For this reason, many teams prefer to update versions of components in a test environment first, then "promote" the resolved (fixed) version through to staging and production environments. 

# Option B : Templated package versions (more safe)

## How

Instead of delegating the upgrade process to kapp-controller, we can query for the latest package ourselves, as part of some CI process. We again need to update the `InstalledPackage` YAML, but now we will need to do it every time a new package version is available.

For a simple way to get the latest package version, we can rely on sort's semver parsing, with:

`LATEST_PKG_VERSION=$(k get packages -o json | jq -r '.items[].spec | select(.publicName == "cert-manager.tce.vmware.com") | .version' | gsort -V | tail -n 1)`

Note - the interfaces around package versioning are still undergoing changes, so this command too may be subject to change too

In this case, its not trivial to use kustomize, as (based on the limited discussion I could find) what it can accept as dynamically provided parameters is very limited. In general, when you go outside the things `kustomize` has good features for, its best to use a "proper" templating tool. So we will use ytt instead to render the version:

`ytt -f vendor -f overlay.yml -f values.yml -v "package_version=$LATEST_PKG_VERSION" | yshard -g ".kind" -o deploy`

Once we have the updated `InstalledPackage` manifest we can then promote it through different environments, deploying it in the best order to minimise risk. 

## Why

So, this is way more work than the first versions, because now we would need to continuously deploy the package definitions through an automated delivery pipeline. However, we benefit from having absolute control over the software versions we deploy across our estate of clusters. We will always get exactly the version we want in the places we want it. Ultimately, to get this level of control, you cannot avoid the need to define a delivery pipeline to do so. 

However, there is another area we can look into to control the packages available - the `PackageRepository`. This won't give control over the packages at the destination, but instead, at the source. We'll look into this next.
