#!/usr/bin/env bats
# Unit tests for audit-log.sh
# Tests: audit log fields (tag, commit, actor) and dry-run prefix
# Validates: Requirements 3.3, 4.4, 6.2

SCRIPT="$BATS_TEST_DIRNAME/../audit-log.sh"

# 1. CREATE operation: actor, operation=CREATE, tag, commit all present
@test "CREATE: output contains actor" {
  run env TAG_EXISTS=false DRY_RUN=false TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Actor: john"* ]]
}

@test "CREATE: output contains operation CREATE" {
  run env TAG_EXISTS=false DRY_RUN=false TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Operation: CREATE"* ]]
}

@test "CREATE: output contains tag" {
  run env TAG_EXISTS=false DRY_RUN=false TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Tag: v1"* ]]
}

@test "CREATE: output contains commit" {
  run env TAG_EXISTS=false DRY_RUN=false TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Commit: abc123"* ]]
}

# 2. RECREATE operation: actor, operation=RECREATE, tag, previous commit, new commit all present
@test "RECREATE: output contains actor" {
  run env TAG_EXISTS=true DRY_RUN=false TAG_VERSION=v2 CURRENT_COMMIT=new456 PREVIOUS_COMMIT=old123 ACTOR=jane bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Actor: jane"* ]]
}

@test "RECREATE: output contains operation RECREATE" {
  run env TAG_EXISTS=true DRY_RUN=false TAG_VERSION=v2 CURRENT_COMMIT=new456 PREVIOUS_COMMIT=old123 ACTOR=jane bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Operation: RECREATE"* ]]
}

@test "RECREATE: output contains tag" {
  run env TAG_EXISTS=true DRY_RUN=false TAG_VERSION=v2 CURRENT_COMMIT=new456 PREVIOUS_COMMIT=old123 ACTOR=jane bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Tag: v2"* ]]
}

@test "RECREATE: output contains previous commit" {
  run env TAG_EXISTS=true DRY_RUN=false TAG_VERSION=v2 CURRENT_COMMIT=new456 PREVIOUS_COMMIT=old123 ACTOR=jane bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] Previous commit: old123"* ]]
}

@test "RECREATE: output contains new commit" {
  run env TAG_EXISTS=true DRY_RUN=false TAG_VERSION=v2 CURRENT_COMMIT=new456 PREVIOUS_COMMIT=old123 ACTOR=jane bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[AUDIT] New commit: new456"* ]]
}

# 3. dry-run=true: output contains [DRY-RUN] prefix
@test "dry-run=true: output contains [DRY-RUN] prefix" {
  run env TAG_EXISTS=false DRY_RUN=true TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY-RUN]"* ]]
}

# 4. dry-run=true: exits 0 after dry-run summary (no tag operations)
@test "dry-run=true: exits with code 0" {
  run env TAG_EXISTS=false DRY_RUN=true TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dry-run=true: output contains 'No changes applied'" {
  run env TAG_EXISTS=false DRY_RUN=true TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY-RUN] No changes applied."* ]]
}

# 5. dry-run=false: no [DRY-RUN] lines in output
@test "dry-run=false: output does not contain [DRY-RUN]" {
  run env TAG_EXISTS=false DRY_RUN=false TAG_VERSION=v1 CURRENT_COMMIT=abc123 ACTOR=john bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" != *"[DRY-RUN]"* ]]
}

# 6. RECREATE with dry-run: [DRY-RUN] says RECREATE
@test "RECREATE with dry-run=true: [DRY-RUN] line mentions RECREATE" {
  run env TAG_EXISTS=true DRY_RUN=true TAG_VERSION=v2 CURRENT_COMMIT=new456 PREVIOUS_COMMIT=old123 ACTOR=jane bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY-RUN] Would RECREATE tag v2"* ]]
}
