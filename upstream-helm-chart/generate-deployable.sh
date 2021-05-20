#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

helm template cert-manager vendor --values values.yaml --namespace cert-manager-chart --create-namespace | yshard -g ".kind" -o "$SCRIPT_DIR/deploy"

