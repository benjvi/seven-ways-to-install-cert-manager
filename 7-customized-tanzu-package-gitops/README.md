
# What

Previously, we looked at the use of `App` to customize Tanzu packages. We noted that, in some cases, customizations could be difficult to understand without reference to the actual manifests in the package. Here, we will look at how the package manifests can be accessed and how we can use `kapp-controller` to deploy manifests checked-in to git.

# How

First, we have to find out the location of the package, which we can get from the Kubernetes cluster hosting our `PackageRepository`:

`k get packages -o json | yq -r ".items[] | select(.metadata.name == \"cert-manager.tce.vmware.com.1.1.0-vmware0\") | .spec.template.spec.fetch[].imgpkgBundle.image"`

This gives an image reference to an [`imgpkgBundle` (TODO)]() for the package. NB: we could replace the version section of the package name by a variable `LATEST_PKG_VERION`, so we could fetch the latest version of a package as we did in section `4-auto-updates`. 

Since `vendir` understands imgpkg bundles, we then define a `vendir.yml` so we can download the package by running `vendir sync`. 

Once downloaded, we are able to see the contents of the package in `vendor/config`. We also can see where any upstream components of the package came from, by looking at `vendor/vendir.yml`

Now we can apply exactly the same overlay as in the previous section, to add labels to all the resources. We run `ytt` to render the manifests (with `yshard` allowing us to segment output files by resource `kind`):

`ytt -f vendor/config --ignore-unknown-comments -f cert-manager.tce.vmware.com-values.yaml -f ytt-overlay-add-label.yml | yshard -g ".kind" -o deploy-continuous`

This creates a set of plain manifests in the output folder, which are ready to be applied. 

We will use kapp-controller to apply the manifests, once again using an `App` object. In this case, this configures `kapp-controller` to connect to the git server for this repo, and reconcile the manifests in the `deploy-continuous` folder with what's running in the cluster. The `App` object also requires a service account, for which we generate the manifest with:

```
kubectl create clusterrolebinding cert-manager-tanzu-package-gitops -n default --clusterrole=cluster-admin --serviceaccount=default:cert-manager-tanzu-package-gitops -o yaml --dry-run=client > deploy-once/ClusterRoleBinding.yml
kubectl create sa cert-manager-tanzu-package-gitops -n default -o yaml --dry-run=client > deploy-once/ServiceAccount.yml
```

Since my git repo, is private, I need to create a secret for the `App` to access it. Since it contains secret data, I just create it imperatively rather than providing a manifest:

`k create secret generic customized-tanzu-package-gitops-deploy-key --from-file=ssh-privatekey=id_rsa`

Then, the contents of the `deploy-once` folder, including a [manually written](https://carvel.dev/kapp-controller/docs/latest/app-spec/) `App`, can be created: `kubectl apply -f deploy-once` 

Now, `kapp-controller` will reconcile the app, as before and cert-manager will be deployed. In future, any changes to the `deploy-continuous` folder will also get deployed within a few seconds.

## Templating 

Although we fully rendered the templates here before checking them into `deploy-continuous`, it is possible also to pass templates to `kapp-controller` and for rendering to be done by the controller, as we did in section `6-customized-tanzu-package`. By doing that, we trade off the ability to do static checks of the rendered config before deployment against the convenience of having `kapp-controller` do eveything needed for updates.

# Why

## Pros

- Able to customize manifests in any way desired
- Package manifest updates are more observable, can see how changes might impact customizations
- Can run standard tooling to validate Kubernetes manifests, before deployment
- Still retain some clarity about what parameters are supported by the package, and what our customizations are
- Still have control over versions being deployed

## Cons

- Complex update process, a CI process to fetch and render manifests is needed in addition to the work `kapp-controller` does to continously deploy the apps
- More possibilities to change manifests in unmaintainable ways, e.g. manually updating the `deploy-continuous` folder rather than regenerating it with `ytt`
