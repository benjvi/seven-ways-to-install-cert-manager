
# What

In addition to the `InstalledPackage` resource we looked at earlier, `kapp-controller` can also manage `App` resources. This is a lower-level resource - when you create an `InstalledPackage` then an `App` is created under the hood. The `App` object does not know anything about versions like `InstalledPackages` do - it is concerned with the details of how to fetch some manifests and how to template them before applying, which it does as part of a continuous reconciliation loop. In short, its a flexible object useful in GitOps-style deployment workflows. We will look at how `App` objects can be used instead of `InstalledPackage`, to install a package with (more or less) arbitrary customizations.

# How

We start very similar to how we started in `3-tanzu-packages`, but instead of fetching an `InstalledPackage` from the Kubernetes API, now we fetch an `App` resource. Before we write out the Kubernetes manifests to the `deploy` folder, we want to make changes to the `App` resource to add additional templating steps.

We will add an additional ytt step, which uses ytt overlays to customize the manifest. Our customization will be [to apply labels to all the items in the manifest](https://github.com/vmware-tanzu/carvel-ytt/tree/develop/examples/k8s-add-global-label).

The step will look something like this:

```
- ytt:
    ignoreUnknownComments: true
    inline:
      pathsFrom:
        - configMapRef:
            name: cert-manager-app-custom-ytt-overlay
    paths:
      - '-'
```

Because rendering has already taken place, we must tell `ytt` to include '-' (STDIN) as part of its paths to template.

So we need to add this to our existing `App` definition, which we will (rather confusingly) also do with a `ytt` overlay - from file `app-overlay-add-ytt-step.yml`.

So, we have an extra step which will be invoked by `kapp-controller`. But now we need to pass the overlay file as a `ConfigMap`. We generate the `ConfigMap` manifest imperatively.

Look into `./generate-deployable.sh` to see all the steps combined, and run it to regenerate the `deploy` folder.

After creating the app with `kubectl apply -f deploy/`, you will be able to see the additional label `custom-label=custom-label-value` present on the new namespace, and deployments within it. It is not present on the pods, because for that we would need to set the label on the deployment's `PodTemplate` too - which we didn't do.

# Why

## Pros

- Unlimited customizability - ytt can modify any field on any resource in the package manifests 
- It's clear what parameters are exposed by the package and which are customizations made by the package consumer
- Customization process (generally) works for upgrading packages as well as on initial install 

## Cons

- Complexity -> the process we went through is somewhat complex, and needs to be performed on every package update
- Certain customizations could be broken on package updates
- Templating tools other than `ytt` and `helm` are not supported
- Difficult to determine what (some) of the templated modifications do without access to the manifests in the package
