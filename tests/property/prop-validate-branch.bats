#!/usr/bin/env bats
# Property test: branch validation
# Property 1: Only refs/heads/main passes; all other refs fail
# Tag: Feature: tag-management-workflow, Property 1: branch validation
# Validates: Requirements 1.2, 1.3

SCRIPT="$BATS_TEST_DIRNAME/../validate-branch.sh"

@test "Property 1: refs/heads/main always passes (100 iterations)" {
  for i in $(seq 1 100); do
    run env GITHUB_REF=refs/heads/main bash "$SCRIPT"
    [ "$status" -eq 0 ] || {
      echo "FAILED: refs/heads/main should pass but got exit $status" >&2
      return 1
    }
  done
}

@test "Property 1: random feature branches always fail (100 iterations)" {
  for i in $(seq 1 100); do
    local branch="refs/heads/feature-${RANDOM}-${RANDOM}"
    run env GITHUB_REF="$branch" bash "$SCRIPT"
    [ "$status" -eq 1 ] || {
      echo "FAILED: '$branch' should fail but got exit $status" >&2
      return 1
    }
  done
}

@test "Property 1: random tag refs always fail (100 iterations)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local ref="refs/tags/v${n}"
    run env GITHUB_REF="$ref" bash "$SCRIPT"
    [ "$status" -eq 1 ] || {
      echo "FAILED: '$ref' should fail but got exit $status" >&2
      return 1
    }
  done
}

@test "Property 1: arbitrary strings always fail (100 iterations)" {
  local refs=(
    "main"
    "refs/heads/main "
    " refs/heads/main"
    "refs/heads/MAIN"
    "refs/heads/Main"
    "refs/remotes/origin/main"
    ""
    "refs/heads/"
    "refs/heads/mainline"
  )
  for i in $(seq 1 100); do
    local idx=$(( i % ${#refs[@]} ))
    local ref="${refs[$idx]}"
    run env GITHUB_REF="$ref" bash "$SCRIPT"
    [ "$status" -eq 1 ] || {
      echo "FAILED: '$ref' should fail but got exit $status" >&2
      return 1
    }
  done
}
