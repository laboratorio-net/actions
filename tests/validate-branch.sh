#!/usr/bin/env bash
# Validates that the current branch is refs/heads/main
# Usage: GITHUB_REF=refs/heads/main ./validate-branch.sh
# Exit 0 if valid, 1 if not main branch
GITHUB_REF="${GITHUB_REF:-}"
if [ "$GITHUB_REF" != "refs/heads/main" ]; then
  echo "Este workflow só pode ser executado na branch main." >&2
  exit 1
fi
exit 0
