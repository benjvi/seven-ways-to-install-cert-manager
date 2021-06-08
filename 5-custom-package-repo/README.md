
# What

Tanzu packages rely on a simple implementation of a package repository that uses container image repositories. This makes it easy to set up your own image repository.

# How

## Relocating the Image

First, you can just move the entire package repository to a location you control, e.g.:

`docker pull projects.registry.vmware.com/tce/main:stable && docker tag projects.registry.vmware.com/tce/main:stable benjvi/pkg-repo:stable && docker push benjvi/pkg-repo:stable`

Then you can update the URL in the `PackageRepository` ( in file `tce-package-repo.yml` ) to match the new repository location. Since its a simple change, even using `kustomize` is not necessary, and we just create a new manifest `relocated-package-repo.yml`.

\[ Note - unfortunately, `kbld` does not find the image reference in the YAML file in this case. In other cases it can perform all the previous steps for you automatically based on the image references in the kubernetes manifests, which is a more convenient way to rewrite image references. \]

Installing the repository - `kubectl apply -f relocated-package-repo.yml` this works, and we can install the packages listed in the output of `kubectl get packages`. This procedure could be useful to make the repo available in an offline environment.

## Customizing the packages available

We could extend this to perform our own selection of the packages to make available in the repo. To do this we need to get an unpacked copy of the repo and make changes.

First, we can get an unpacked copy of the repo by running `vendir sync`, so we have a copy of the files in the `PackageRepository` container image saved under `vendor`.

Now we can modify it. The `PackageRepository` contains a list of package objects in a `packages/packages.yaml` file. In this case, we are just querying the YAML so don't need any templating tool. Use `yq` to select the packages we want:

```
mkdir -p deploy/packages
cat vendor/packages/packages.yaml | yq -sy --argjson whitelist '["cert-manager.tce.vmware.com.1.1.0-vmware0","velero.tce.vmware.com.1.5.2-vmware0"]' '.[] | select( .metadata.name as $in | $whitelist | any( . == $in) )' > deploy/packages/packages.yaml
```

Now the package repository is ready. We can push it to the new location with `imgpkg` (remember to change the tag to point to a repository you control):
`imgpkg push -i benjvi/custom-package-repo:stable -f deploy`

As before, we create another `PackageRepository` manifest, in `custom-package-repo.yml`. After applying -`kubectl apply -f custom-package-repo.yml` - querying the packages with `kubectl get packages` will show only the two selected packages available in the cluster.

## Offline / Air-Gapped Packages

If we are relocating the images into a Docker repository that is available in an air-gapped environment, we have to be aware that the packages are still in the public repo, and therefore any offline package installation will fail. We need to perform an additional step to relocate them into our private repo. In this case, we can use `kbld` :

```
mkdir -p offline-deploy/packages
kbld relocate -f deploy/packages/packages.yaml --repository docker.io/benjvi/custom-package-repo-packages > offline-deploy/packages/packages.yaml
```
Then publish the repository:
`imgpkg push -i benjvi/offline-package-repo:stable -f offline-deploy`

Finally, we can create this `PackageRepository` from the `offline-package-repo.yml` manifest.

## Deploying

With a `PackageRepository` available, we can now deploy in exactly the same way as we deployed Tanzu packages in previous sections.

# Why

In cases where you want to install packages into air-gapped environment, a process like this to publish packages to a repository in your environment is a necessity.

The reason for this air-gapping is so that artifacts can be subjected to some stringent checks before teams are allowed to use them within the company. The primary reason for needing to do these checks is often security or compliance concerns.

There also exists the technical possibility to provide some control over version updates. Updates can be limited to validated versions of updates; versions that don't work in your organization can be excluded. This model is similar to the use of Windows Update Servers within organizations, which mediate updates, allowing for control of installation of Windows Updates onto workstations. __However__, since the management of platforms is generally quite centralized, with a platform team validating and taking responsibility for the components they deploy, this approach used *for this reason* doesn't offer many additional benefits. 

