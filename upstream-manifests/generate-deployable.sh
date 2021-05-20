#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cat "$SCRIPT_DIR/vendor/cert-manager.yaml" | yshard -g ".kind" -o "$SCRIPT_DIR/deploy"
