# *Seven Ways To Install Cert Manager* -  A Guide to Package Installation on Kubernetes

There are lots of different ways to install software packages onto Kubernetes. 

Some of them have seen wide adoption in the community, like distributing plain Kubernetes manifests and Helm charts.

VMware Tanzu is moving towards a different approach, using `kapp-controller` packages, a still emerging and not (yet) widely adopted approach - but one which seems to offer some advantages. 

This repo, using cert-manager as an example, gives an overview of the most popular practices for installing packages onto Kubernetes, and how some of the (current) capabilities of `kapp-controller` might fit in.

For each approach to packaging, we will be interested in (and possibly evaluating tradeoffs between):
- Making software easy to install and update
- Making the upgrade process safe and controllable
- Allowing package authors to give users safe ways to parameterize the software
- Allowing users to customize the software in ways not foreseen by the package authors
- Giving users insight into the content of what will be deployed - the version increment, manifest changeset, etc

## Dependencies

To follow along with the steps in each section, you need: 
- A Tanzu Kubernetes cluster with the latest (alpha) version of `kapp-controller` installed
- Carvel tools installed, as well as `kubectl`,`helm`,`kustomize` and `yq`
- [`yshard`](https://github.com/benjvi/yshard), which is used to split manifest files to make them easier to inspect

## Why Cert Manager?

Some Kubernetes packages are simpler than others. Cert Manager is a package that is not *too complicated*, and extremely widely used, but has some interesting / challenging features as an installable package:
- It heavily uses CRDs, which are (a) extremely verbose (b) *manifests* of little relevance to package consumers (c) can cause dependency issues during deployment
- It also uses `mutatingwebhookconfigurations` and `validatingwebhookconfigurations` which can also cause deployment issues
- It's not natively designed / maintained to fit in with the packaging approach used in Tanzu

## Testing

When you install stuff, you should always test it works before declaring success. I include two sample manifests `certmanager-clusterissuer.yml` and `certmanager-cert.yml` that can be used to generate a certificate. The `certmanager-clusterissuer.yml` in this case just generates self-signed certificates, so there's no dependencies. After running `kubectl apply -f certmanager-clusterissuer.yml` and `kubectl apply -f certmanager-cert.yml`, running `kubectl get certs` should show you a certificate `test-cert-manager-certificate` with `READY` set to `True`.

You may want to perform this validation for each method of installation.
