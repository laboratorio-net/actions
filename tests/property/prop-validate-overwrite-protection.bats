#!/usr/bin/env bats
# Property test: overwrite protection
# Property 5: For any existing tag with force=false, the protection step must fail
# Tag: Feature: tag-management-workflow, Property 5: overwrite protection
# Validates: Requirements 5.3

SCRIPT="$BATS_TEST_DIRNAME/../validate-overwrite-protection.sh"

@test "Property 5: any existing tag with force=false always fails (100 iterations)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    run env TAG_EXISTS=true FORCE=false TAG_VERSION="$tag" bash "$SCRIPT"
    [ "$status" -eq 1 ] || {
      echo "FAILED: TAG_EXISTS=true FORCE=false TAG_VERSION=$tag should fail but got exit $status" >&2
      return 1
    }
  done
}

@test "Property 5: any existing tag with force=true always passes (100 iterations)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    run env TAG_EXISTS=true FORCE=true TAG_VERSION="$tag" bash "$SCRIPT"
    [ "$status" -eq 0 ] || {
      echo "FAILED: TAG_EXISTS=true FORCE=true TAG_VERSION=$tag should pass but got exit $status" >&2
      return 1
    }
  done
}

@test "Property 5: any non-existing tag always passes regardless of force (100 iterations)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    local force
    if (( i % 2 == 0 )); then force=true; else force=false; fi
    run env TAG_EXISTS=false FORCE="$force" TAG_VERSION="$tag" bash "$SCRIPT"
    [ "$status" -eq 0 ] || {
      echo "FAILED: TAG_EXISTS=false FORCE=$force TAG_VERSION=$tag should pass but got exit $status" >&2
      return 1
    }
  done
}

@test "Property 5: error message always contains tag name when failing (100 iterations)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    run env TAG_EXISTS=true FORCE=false TAG_VERSION="$tag" bash "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"$tag"* ]] || {
      echo "FAILED: error message for TAG_VERSION=$tag does not contain tag name. Output: $output" >&2
      return 1
    }
  done
}
