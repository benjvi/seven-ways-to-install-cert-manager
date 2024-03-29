
# What

The cert-manager project provides a set of Kubernetes manifests for each release that can be deployed on the cluster.

# How

This could be applied directly with kubectl, pulling from a specific Github release, like so:
 `kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml`

Here, we use `vendir` to download the manifest before applying it. This allows us to inspect the manifests, and we can make changes to them, if required, using a YAML overlay tool like `ytt` or `kustomize`. In this example, the only processing of the manifest we do is to run `yshard`, which splits up the manifests into separate files by the Kubernetes reource `kind`.

Deploy the `deploy/` folder (generated by `./generate-deployable.sh`) with `kubectl apply -f deploy/`.

Once you have validated the install to your satisfaction, cleanup with `kubectl delete -f deploy/`. You will need to clean up resources created from the `deploy` folders in each section going forward, so each installation method can be executed as a fresh install.

# Why

## Pros

 - The most straightforward way of installing software on kubernetes
 - Relies only on standard Kubernetes constructs
 - Very flexible, lots of tooling (like Kustomize) exists to customize manifests, or lint them before deployment

## Cons

- No way to set control over a version range, can only fetch latest versions
- Not clear what manifest customizations should work and what shouldn't
- If using plain kubectl to apply manifests, old objects won't be removed

# Suggested Extensions

- Use kustomize or ytt to set the namespace we want
- Use kustomize to set labels on everything - [with a transformer](https://patrick-picard.medium.com/kustomization-applying-labels-gotchas-a53f87277661)
