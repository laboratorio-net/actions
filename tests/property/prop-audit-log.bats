#!/usr/bin/env bats
# Property test: audit log required fields
# Property 4: Log de auditoria contém todos os campos obrigatórios
# Validates: Requirements 3.3, 4.4
# Tag: Feature: tag-management-workflow, Property 4: audit log required fields

SCRIPT="$BATS_TEST_DIRNAME/../audit-log.sh"

# Helper: generate a random 8-char hex commit hash
random_commit() {
  printf '%08x' $(( RANDOM * RANDOM % 0xFFFFFFFF ))
}

# Helper: generate a random actor name
random_actor() {
  local names=("alice" "bob" "carol" "dave" "eve" "frank" "grace" "heidi" "ivan" "judy")
  local idx=$(( RANDOM % ${#names[@]} ))
  echo "${names[$idx]}${RANDOM}"
}

@test "Property 4: CREATE operation always contains tag, commit, and actor in log (100 iterations)" {
  # Validates: Requirements 3.3, 4.4
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    local commit
    commit=$(random_commit)
    local actor
    actor=$(random_actor)

    run env \
      TAG_EXISTS=false \
      DRY_RUN=false \
      TAG_VERSION="$tag" \
      CURRENT_COMMIT="$commit" \
      PREVIOUS_COMMIT="" \
      ACTOR="$actor" \
      bash "$SCRIPT"

    [ "$status" -eq 0 ] || {
      echo "FAILED: script exited with $status for tag=$tag commit=$commit actor=$actor" >&2
      return 1
    }

    [[ "$output" == *"$tag"* ]] || {
      echo "FAILED: output does not contain tag '$tag'. Output: $output" >&2
      return 1
    }

    [[ "$output" == *"$commit"* ]] || {
      echo "FAILED: output does not contain commit '$commit'. Output: $output" >&2
      return 1
    }

    [[ "$output" == *"$actor"* ]] || {
      echo "FAILED: output does not contain actor '$actor'. Output: $output" >&2
      return 1
    }
  done
}

@test "Property 4: RECREATE operation always contains tag, new commit, previous commit, and actor in log (100 iterations)" {
  # Validates: Requirements 3.3, 4.4
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    local new_commit
    new_commit=$(random_commit)
    local prev_commit
    prev_commit=$(random_commit)
    local actor
    actor=$(random_actor)

    run env \
      TAG_EXISTS=true \
      DRY_RUN=false \
      TAG_VERSION="$tag" \
      CURRENT_COMMIT="$new_commit" \
      PREVIOUS_COMMIT="$prev_commit" \
      ACTOR="$actor" \
      bash "$SCRIPT"

    [ "$status" -eq 0 ] || {
      echo "FAILED: script exited with $status for tag=$tag new=$new_commit prev=$prev_commit actor=$actor" >&2
      return 1
    }

    [[ "$output" == *"$tag"* ]] || {
      echo "FAILED: output does not contain tag '$tag'. Output: $output" >&2
      return 1
    }

    [[ "$output" == *"$new_commit"* ]] || {
      echo "FAILED: output does not contain new commit '$new_commit'. Output: $output" >&2
      return 1
    }

    [[ "$output" == *"$prev_commit"* ]] || {
      echo "FAILED: output does not contain previous commit '$prev_commit'. Output: $output" >&2
      return 1
    }

    [[ "$output" == *"$actor"* ]] || {
      echo "FAILED: output does not contain actor '$actor'. Output: $output" >&2
      return 1
    }
  done
}

@test "Property 4: dry-run=false never produces [DRY-RUN] lines (100 iterations)" {
  # Validates: Requirements 6.2, 6.3
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"
    local commit
    commit=$(random_commit)
    local actor
    actor=$(random_actor)
    # Alternate between CREATE and RECREATE
    local tag_exists="false"
    local prev_commit=""
    if (( i % 2 == 0 )); then
      tag_exists="true"
      prev_commit=$(random_commit)
    fi

    run env \
      TAG_EXISTS="$tag_exists" \
      DRY_RUN=false \
      TAG_VERSION="$tag" \
      CURRENT_COMMIT="$commit" \
      PREVIOUS_COMMIT="$prev_commit" \
      ACTOR="$actor" \
      bash "$SCRIPT"

    [[ "$output" != *"[DRY-RUN]"* ]] || {
      echo "FAILED: output contains [DRY-RUN] when dry-run=false for tag=$tag. Output: $output" >&2
      return 1
    }
  done
}
