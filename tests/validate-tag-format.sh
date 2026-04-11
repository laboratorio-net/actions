#!/usr/bin/env bash
# Validates tag version format: must match ^v[0-9]+$
# Usage: validate-tag-format.sh <tag-version>
# Exit 0 if valid, 1 if invalid
TAG_VERSION="$1"
if ! [[ "$TAG_VERSION" =~ ^v[0-9]+$ ]]; then
  echo "Formato inválido: '$TAG_VERSION'. Use o padrão vN (ex: v1, v2, v3)." >&2
  exit 1
fi
exit 0
