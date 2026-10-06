#!/usr/bin/env bash
# Print a template with its ${VAR} placeholders filled from the environment; fails on unset ones.
# `just render` runs this under `sops exec-env` with the secrets.yaml next to the template.
set -euo pipefail
vars=$(grep -o '\${[A-Za-z_][A-Za-z0-9_]*}' "$1" | sort -u || true)
for v in $vars; do
  name=${v#\$\{}
  name=${name%\}}
  if [ -z "${!name+x}" ]; then
    echo "render-template: ${name} is not set" >&2
    exit 1
  fi
done
envsubst "$vars" <"$1"
