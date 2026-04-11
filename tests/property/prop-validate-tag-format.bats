#!/usr/bin/env bats
# Property test: tag format validation
# Property 2: For any string, validate-tag-format.sh result must be equivalent to testing ^v[0-9]+$
# Validates: Requirements 2.2, 2.3
# Tag: Feature: tag-management-workflow, Property 2: tag format validation

SCRIPT="$BATS_TEST_DIRNAME/../validate-tag-format.sh"

# Helper: check if string matches ^v[0-9]+$ using bash
matches_pattern() {
  [[ "$1" =~ ^v[0-9]+$ ]]
}

@test "Property 2: random strings - script result matches regex (100 iterations)" {
  local iterations=100
  local passed=0

  # Pool of random-ish strings to test
  local test_strings=(
    "v1" "v2" "v10" "v100" "v999"
    "1" "v" "V1" "v1.0" "v1-beta" ""
    "v0" "v01" "vv1" "1v" "v1v"
    "v123456" "v-1" "v1 " " v1" "v1a"
  )

  # Generate 100 random test cases by combining patterns
  for i in $(seq 1 $iterations); do
    # Generate a varied string based on iteration
    local idx=$(( i % ${#test_strings[@]} ))
    local input="${test_strings[$idx]}"

    # Run the script
    run bash "$SCRIPT" "$input"
    local script_exit=$status

    # Check expected result using the reference regex
    if matches_pattern "$input"; then
      local expected_exit=0
    else
      local expected_exit=1
    fi

    [ "$script_exit" -eq "$expected_exit" ] || {
      echo "FAILED for input='$input': script=$script_exit expected=$expected_exit" >&2
      return 1
    }
    passed=$(( passed + 1 ))
  done

  echo "Passed $passed/$iterations iterations"
}

@test "Property 2: generated valid tags always pass (100 iterations)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local input="v${n}"
    run bash "$SCRIPT" "$input"
    [ "$status" -eq 0 ] || {
      echo "FAILED: valid input '$input' was rejected" >&2
      return 1
    }
  done
}

@test "Property 2: generated invalid tags always fail (100 iterations)" {
  local invalid_patterns=(
    "${RANDOM}"           # no v prefix
    "V${RANDOM}"          # uppercase V
    "v${RANDOM}.0"        # dot notation
    "v${RANDOM}-beta"     # suffix
    "v${RANDOM}x"         # letter suffix
    ""                    # empty
    "v"                   # v only
  )
  local count=0
  for i in $(seq 1 100); do
    local idx=$(( i % ${#invalid_patterns[@]} ))
    local input="${invalid_patterns[$idx]}"
    # Re-evaluate to get fresh RANDOM values
    case $idx in
      0) input="${RANDOM}" ;;
      1) input="V${RANDOM}" ;;
      2) input="v${RANDOM}.0" ;;
      3) input="v${RANDOM}-beta" ;;
      4) input="v${RANDOM}x" ;;
      5) input="" ;;
      6) input="v" ;;
    esac
    run bash "$SCRIPT" "$input"
    [ "$status" -eq 1 ] || {
      echo "FAILED: invalid input '$input' was accepted" >&2
      return 1
    }
    count=$(( count + 1 ))
  done
}
