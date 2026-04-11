#!/usr/bin/env bats
# Unit tests for validate-tag-format.sh
# Tests: tag format validation (^v[0-9]+$)

SCRIPT="$BATS_TEST_DIRNAME/../validate-tag-format.sh"

# Valid inputs
@test "v1 is valid" {
  run bash "$SCRIPT" "v1"
  [ "$status" -eq 0 ]
}

@test "v10 is valid" {
  run bash "$SCRIPT" "v10"
  [ "$status" -eq 0 ]
}

@test "v100 is valid" {
  run bash "$SCRIPT" "v100"
  [ "$status" -eq 0 ]
}

# Invalid inputs
@test "1 is invalid (no v prefix)" {
  run bash "$SCRIPT" "1"
  [ "$status" -eq 1 ]
}

@test "v is invalid (no number)" {
  run bash "$SCRIPT" "v"
  [ "$status" -eq 1 ]
}

@test "v1.0 is invalid (dot notation)" {
  run bash "$SCRIPT" "v1.0"
  [ "$status" -eq 1 ]
}

@test "V1 is invalid (uppercase V)" {
  run bash "$SCRIPT" "V1"
  [ "$status" -eq 1 ]
}

@test "v1-beta is invalid (suffix)" {
  run bash "$SCRIPT" "v1-beta"
  [ "$status" -eq 1 ]
}

@test "empty string is invalid" {
  run bash "$SCRIPT" ""
  [ "$status" -eq 1 ]
}

@test "invalid input shows error message with expected format" {
  run bash "$SCRIPT" "invalid"
  [ "$status" -eq 1 ]
  [[ "$output" == *"vN"* ]]
}
