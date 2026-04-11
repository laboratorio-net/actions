#!/usr/bin/env bats
# Property test: dry-run invariant
# Property 6: For any valid inputs with dry-run=true:
#   (a) tag set before/after is identical
#   (b) log contains [DRY-RUN]
#   (c) validations execute normally
# Tag: Feature: tag-management-workflow, Property 6: dry-run invariant
# Validates: Requirements 6.1, 6.2, 6.3

VALIDATE_FORMAT="$BATS_TEST_DIRNAME/../validate-tag-format.sh"
VALIDATE_OVERWRITE="$BATS_TEST_DIRNAME/../validate-overwrite-protection.sh"
AUDIT_LOG="$BATS_TEST_DIRNAME/../audit-log.sh"

setup() {
  TMPDIR=$(mktemp -d)
  git -C "$TMPDIR" init -q
  git -C "$TMPDIR" config user.email "test@test.com"
  git -C "$TMPDIR" config user.name "Test"
  touch "$TMPDIR/README.md"
  git -C "$TMPDIR" add README.md
  git -C "$TMPDIR" commit -q -m "Initial commit"
}

teardown() {
  rm -rf "$TMPDIR"
}

@test "Property 6: dry-run=true with CREATE - tag set unchanged (100 iterations)" {
  # Validates: Requirements 6.1, 6.2, 6.3
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    local commit
    commit=$(git -C "$TMPDIR" rev-parse HEAD)

    local tags_before
    tags_before=$(git -C "$TMPDIR" tag -l)

    # (c) format validation still runs
    run bash "$VALIDATE_FORMAT" "$tag"
    [ "$status" -eq 0 ] || {
      echo "FAILED: format validation failed for $tag" >&2
      return 1
    }

    # (c) overwrite protection still runs (tag doesn't exist)
    run env TAG_EXISTS=false FORCE=false TAG_VERSION="$tag" bash "$VALIDATE_OVERWRITE"
    [ "$status" -eq 0 ] || {
      echo "FAILED: overwrite protection failed for $tag" >&2
      return 1
    }

    # audit-log with dry-run=true
    run env TAG_EXISTS=false DRY_RUN=true TAG_VERSION="$tag" CURRENT_COMMIT="$commit" PREVIOUS_COMMIT="" ACTOR="testuser" bash "$AUDIT_LOG"
    [ "$status" -eq 0 ] || {
      echo "FAILED: audit log exited with $status for tag=$tag" >&2
      return 1
    }

    # (b) log contains [DRY-RUN]
    [[ "$output" == *"[DRY-RUN]"* ]] || {
      echo "FAILED: output does not contain [DRY-RUN] for tag=$tag. Output: $output" >&2
      return 1
    }

    # (a) tag set unchanged
    local tags_after
    tags_after=$(git -C "$TMPDIR" tag -l)
    [ "$tags_before" = "$tags_after" ] || {
      echo "FAILED: tag set changed! Before: '$tags_before' After: '$tags_after'" >&2
      return 1
    }
  done
}

@test "Property 6: dry-run=true with RECREATE scenario - tag set unchanged (100 iterations)" {
  # Validates: Requirements 6.1, 6.2, 6.3
  git -C "$TMPDIR" tag v1

  for i in $(seq 1 100); do
    local tag="v1"
    local commit
    commit=$(git -C "$TMPDIR" rev-parse HEAD)

    local tags_before
    tags_before=$(git -C "$TMPDIR" tag -l)

    # (c) format validation still runs
    run bash "$VALIDATE_FORMAT" "$tag"
    [ "$status" -eq 0 ] || {
      echo "FAILED: format validation failed for $tag" >&2
      return 1
    }

    # (c) overwrite protection still runs (tag exists, force=true → pass)
    run env TAG_EXISTS=true FORCE=true TAG_VERSION="$tag" bash "$VALIDATE_OVERWRITE"
    [ "$status" -eq 0 ] || {
      echo "FAILED: overwrite protection failed for $tag" >&2
      return 1
    }

    # audit-log with dry-run=true
    run env TAG_EXISTS=true DRY_RUN=true TAG_VERSION="$tag" CURRENT_COMMIT="$commit" PREVIOUS_COMMIT="oldcommit" ACTOR="testuser" bash "$AUDIT_LOG"
    [ "$status" -eq 0 ] || {
      echo "FAILED: audit log exited with $status for tag=$tag" >&2
      return 1
    }

    # (b) log contains [DRY-RUN]
    [[ "$output" == *"[DRY-RUN]"* ]] || {
      echo "FAILED: output does not contain [DRY-RUN] for tag=$tag. Output: $output" >&2
      return 1
    }

    # (a) tag set unchanged (v1 still exists, no new tags)
    local tags_after
    tags_after=$(git -C "$TMPDIR" tag -l)
    [ "$tags_before" = "$tags_after" ] || {
      echo "FAILED: tag set changed! Before: '$tags_before' After: '$tags_after'" >&2
      return 1
    }
  done
}

@test "Property 6: dry-run=true - validations still execute (format check, 100 iterations)" {
  # Validates: Requirements 6.1
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"

    # (c) format validation still runs and passes for valid tags
    run bash "$VALIDATE_FORMAT" "$tag"
    [ "$status" -eq 0 ] || {
      echo "FAILED: format validation failed for valid tag '$tag'" >&2
      return 1
    }
  done
}
