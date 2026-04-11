#!/usr/bin/env bash
# Generates audit log and handles dry-run
# Usage: TAG_EXISTS=false DRY_RUN=false TAG_VERSION=v1 CURRENT_COMMIT=abc PREVIOUS_COMMIT= ACTOR=user ./audit-log.sh
TAG_EXISTS="${TAG_EXISTS:-false}"
DRY_RUN="${DRY_RUN:-false}"
TAG_VERSION="${TAG_VERSION:-}"
CURRENT_COMMIT="${CURRENT_COMMIT:-}"
PREVIOUS_COMMIT="${PREVIOUS_COMMIT:-}"
ACTOR="${ACTOR:-}"

if [ "$TAG_EXISTS" = "true" ]; then
  OPERATION="RECREATE"
else
  OPERATION="CREATE"
fi

echo "[AUDIT] Actor: $ACTOR"
echo "[AUDIT] Operation: $OPERATION"
echo "[AUDIT] Tag: $TAG_VERSION"
if [ "$OPERATION" = "RECREATE" ]; then
  echo "[AUDIT] Previous commit: $PREVIOUS_COMMIT"
  echo "[AUDIT] New commit: $CURRENT_COMMIT"
else
  echo "[AUDIT] Commit: $CURRENT_COMMIT"
fi

if [ "$DRY_RUN" = "true" ]; then
  echo "[DRY-RUN] Would $OPERATION tag $TAG_VERSION"
  echo "[DRY-RUN] Target commit: $CURRENT_COMMIT"
  echo "[DRY-RUN] No changes applied."
  exit 0
fi
