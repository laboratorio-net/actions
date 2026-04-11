#!/usr/bin/env bats
# Unit tests for validate-branch.sh
# Tests: branch validation (only refs/heads/main passes)

SCRIPT="$BATS_TEST_DIRNAME/../validate-branch.sh"

@test "refs/heads/main passes" {
  run env GITHUB_REF=refs/heads/main bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "refs/heads/feature-x fails" {
  run env GITHUB_REF=refs/heads/feature-x bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "refs/tags/v1 fails" {
  run env GITHUB_REF=refs/tags/v1 bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "empty string fails" {
  run env GITHUB_REF= bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "refs/heads/main-extra fails (not exact match)" {
  run env GITHUB_REF=refs/heads/main-extra bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "main (without refs/heads/) fails" {
  run env GITHUB_REF=main bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "refs/heads/develop fails" {
  run env GITHUB_REF=refs/heads/develop bash "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "error message mentions main branch" {
  run env GITHUB_REF=refs/heads/feature bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"main"* ]]
}
