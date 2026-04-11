#!/usr/bin/env bash
# Validates overwrite protection logic
# Usage: TAG_EXISTS=true FORCE=false TAG_VERSION=v1 ./validate-overwrite-protection.sh
# Exit 0 if allowed to proceed, 1 if should fail
TAG_EXISTS="${TAG_EXISTS:-false}"
FORCE="${FORCE:-false}"
TAG_VERSION="${TAG_VERSION:-}"

if [ "$TAG_EXISTS" = "true" ] && [ "$FORCE" = "false" ]; then
  echo "A tag '$TAG_VERSION' já existe. Defina force: true para sobrescrever." >&2
  exit 1
fi
exit 0
