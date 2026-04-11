#!/usr/bin/env bats
# Unit tests for validate-overwrite-protection.sh
# Tests: overwrite protection logic

SCRIPT="$BATS_TEST_DIRNAME/../validate-overwrite-protection.sh"

@test "TAG_EXISTS=true, force=false → fails" {
  run env TAG_EXISTS=true FORCE=false TAG_VERSION=v1 bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "TAG_EXISTS=true, force=false → error message mentions tag name" {
  run env TAG_EXISTS=true FORCE=false TAG_VERSION=v1 bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"v1"* ]]
}

@test "TAG_EXISTS=true, force=false → error message mentions force: true" {
  run env TAG_EXISTS=true FORCE=false TAG_VERSION=v1 bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"force: true"* ]]
}

@test "TAG_EXISTS=true, force=true → passes" {
  run env TAG_EXISTS=true FORCE=true TAG_VERSION=v1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "TAG_EXISTS=false, force=false → passes" {
  run env TAG_EXISTS=false FORCE=false TAG_VERSION=v1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "TAG_EXISTS=false, force=true → passes" {
  run env TAG_EXISTS=false FORCE=true TAG_VERSION=v1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "TAG_EXISTS=false, force unset → passes" {
  run env TAG_EXISTS=false TAG_VERSION=v1 bash "$SCRIPT"
  [ "$status" -eq 0 ]
}
