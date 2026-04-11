#!/usr/bin/env bats
# Integration tests for tag-management-workflow
# Simulates the full pipeline by calling individual scripts in sequence,
# using a local git repo with a bare repo as "remote".
# Requirements: 1.2, 1.3, 2.2, 2.3, 3.1, 4.1, 4.2, 4.3, 5.3, 5.4, 6.1, 6.2, 6.3

VALIDATE_BRANCH="$BATS_TEST_DIRNAME/../validate-branch.sh"
VALIDATE_FORMAT="$BATS_TEST_DIRNAME/../validate-tag-format.sh"
VALIDATE_OVERWRITE="$BATS_TEST_DIRNAME/../validate-overwrite-protection.sh"
AUDIT_LOG="$BATS_TEST_DIRNAME/../audit-log.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# run_pipeline TAG_VERSION FORCE DRY_RUN GITHUB_REF
# Simulates the full workflow pipeline against REPO_DIR / REMOTE_DIR.
# Sets: PIPELINE_OUTPUT, PIPELINE_STATUS, TAG_EXISTS_RESULT
run_pipeline() {
  local tag_version="$1"
  local force="$2"
  local dry_run="$3"
  local github_ref="${4:-refs/heads/main}"

  PIPELINE_OUTPUT=""
  PIPELINE_STATUS=0

  # Step 1: validate-branch
  local out
  out=$(env GITHUB_REF="$github_ref" bash "$VALIDATE_BRANCH" 2>&1)
  if [ $? -ne 0 ]; then
    PIPELINE_OUTPUT="$out"
    PIPELINE_STATUS=1
    return 1
  fi

  # Step 2: validate-tag-format
  out=$(bash "$VALIDATE_FORMAT" "$tag_version" 2>&1)
  if [ $? -ne 0 ]; then
    PIPELINE_OUTPUT="$out"
    PIPELINE_STATUS=1
    return 1
  fi

  # Step 3: check tag existence in remote (bare repo)
  local tag_exists="false"
  local previous_commit=""
  if git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR" "refs/tags/$tag_version" | grep -q .; then
    tag_exists="true"
    previous_commit=$(git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR" "refs/tags/$tag_version" | awk '{print $1}')
  fi

  local current_commit
  current_commit=$(git -C "$REPO_DIR" rev-parse HEAD)

  # Step 4: validate-overwrite-protection
  out=$(env TAG_EXISTS="$tag_exists" FORCE="$force" TAG_VERSION="$tag_version" bash "$VALIDATE_OVERWRITE" 2>&1)
  if [ $? -ne 0 ]; then
    PIPELINE_OUTPUT="$out"
    PIPELINE_STATUS=1
    return 1
  fi

  # Step 5: audit-log (with DRY_RUN flag)
  out=$(env TAG_EXISTS="$tag_exists" DRY_RUN="$dry_run" TAG_VERSION="$tag_version" \
    CURRENT_COMMIT="$current_commit" PREVIOUS_COMMIT="$previous_commit" \
    ACTOR="testuser" bash "$AUDIT_LOG" 2>&1)
  local audit_status=$?
  PIPELINE_OUTPUT="$out"

  if [ "$dry_run" = "true" ]; then
    PIPELINE_STATUS=$audit_status
    return $audit_status
  fi

  # Step 6: if TAG_EXISTS=true, delete tag from remote and local
  if [ "$tag_exists" = "true" ]; then
    git -C "$REPO_DIR" push "$REMOTE_DIR" --delete "$tag_version" > /dev/null 2>&1
    git -C "$REPO_DIR" tag -d "$tag_version" > /dev/null 2>&1
  fi

  # Step 7: create tag and push to remote
  git -C "$REPO_DIR" tag "$tag_version" > /dev/null 2>&1
  git -C "$REPO_DIR" push "$REMOTE_DIR" "$tag_version" > /dev/null 2>&1

  PIPELINE_STATUS=0
  return 0
}

# ---------------------------------------------------------------------------
# Setup / Teardown
# ---------------------------------------------------------------------------

setup() {
  TMPDIR=$(mktemp -d)
  REMOTE_DIR="$TMPDIR/remote.git"
  REPO_DIR="$TMPDIR/repo"

  # Create bare repo (simulates remote)
  git init --bare -q "$REMOTE_DIR"

  # Create local repo and push initial commit
  git init -q "$REPO_DIR"
  git -C "$REPO_DIR" config user.email "test@test.com"
  git -C "$REPO_DIR" config user.name "Test"
  echo "init" > "$REPO_DIR/README.md"
  git -C "$REPO_DIR" add README.md
  git -C "$REPO_DIR" commit -q -m "Initial commit"
  git -C "$REPO_DIR" push -q "$REMOTE_DIR" HEAD:refs/heads/main
}

teardown() {
  rm -rf "$TMPDIR"
}

# ---------------------------------------------------------------------------
# Happy path: create new tag (tag does not exist)
# Requirements: 3.1
# ---------------------------------------------------------------------------

@test "integration: criação de tag inexistente (happy path)" {
  run_pipeline "v1" "false" "false" "refs/heads/main"

  [ "$PIPELINE_STATUS" -eq 0 ]

  # Tag must exist in remote
  git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR" "refs/tags/v1" | grep -q "refs/tags/v1"

  # Tag must point to HEAD
  local head
  head=$(git -C "$REPO_DIR" rev-parse HEAD)
  local tag_commit
  tag_commit=$(git -C "$REPO_DIR" rev-parse "v1")
  [ "$tag_commit" = "$head" ]
}

# ---------------------------------------------------------------------------
# Recreate existing tag with force=true
# Requirements: 4.1, 4.2, 4.3
# ---------------------------------------------------------------------------

@test "integration: recriação de tag existente com force=true" {
  # Create initial tag pointing to first commit
  git -C "$REPO_DIR" tag "v1"
  git -C "$REPO_DIR" push -q "$REMOTE_DIR" "v1"
  local old_commit
  old_commit=$(git -C "$REPO_DIR" rev-parse HEAD)

  # Add a new commit so HEAD advances
  echo "update" > "$REPO_DIR/file.txt"
  git -C "$REPO_DIR" add file.txt
  git -C "$REPO_DIR" commit -q -m "Second commit"
  local new_head
  new_head=$(git -C "$REPO_DIR" rev-parse HEAD)

  run_pipeline "v1" "true" "false" "refs/heads/main"

  [ "$PIPELINE_STATUS" -eq 0 ]

  # Tag must exist in remote and point to new HEAD
  git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR" "refs/tags/v1" | grep -q "refs/tags/v1"

  local tag_commit
  tag_commit=$(git -C "$REPO_DIR" rev-parse "v1")
  [ "$tag_commit" = "$new_head" ]
  [ "$tag_commit" != "$old_commit" ]
}

# ---------------------------------------------------------------------------
# Fail when tag exists and force=false
# Requirements: 5.3, 5.4
# ---------------------------------------------------------------------------

@test "integration: falha com tag existente e force=false" {
  # Create tag in remote
  git -C "$REPO_DIR" tag "v1"
  git -C "$REPO_DIR" push -q "$REMOTE_DIR" "v1"

  run_pipeline "v1" "false" "false" "refs/heads/main" || true

  [ "$PIPELINE_STATUS" -ne 0 ]
  [[ "$PIPELINE_OUTPUT" == *"force: true"* ]]
}

# ---------------------------------------------------------------------------
# Dry-run: tag does not exist
# Requirements: 6.1, 6.2, 6.3
# ---------------------------------------------------------------------------

@test "integration: dry-run com tag inexistente — sem alterações no repositório" {
  local tags_before
  tags_before=$(git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR")

  run_pipeline "v1" "false" "true" "refs/heads/main"

  [ "$PIPELINE_STATUS" -eq 0 ]
  [[ "$PIPELINE_OUTPUT" == *"[DRY-RUN]"* ]]

  # Remote must be unchanged
  local tags_after
  tags_after=$(git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR")
  [ "$tags_before" = "$tags_after" ]
}

# ---------------------------------------------------------------------------
# Dry-run: tag already exists (recreate scenario)
# Requirements: 6.1, 6.2, 6.3
# ---------------------------------------------------------------------------

@test "integration: dry-run com tag existente — sem alterações no repositório" {
  # Create tag in remote
  git -C "$REPO_DIR" tag "v1"
  git -C "$REPO_DIR" push -q "$REMOTE_DIR" "v1"

  local tags_before
  tags_before=$(git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR")

  run_pipeline "v1" "true" "true" "refs/heads/main"

  [ "$PIPELINE_STATUS" -eq 0 ]
  [[ "$PIPELINE_OUTPUT" == *"[DRY-RUN]"* ]]
  [[ "$PIPELINE_OUTPUT" == *"RECREATE"* ]]

  # Remote must be unchanged
  local tags_after
  tags_after=$(git -C "$REPO_DIR" ls-remote --tags "$REMOTE_DIR")
  [ "$tags_before" = "$tags_after" ]
}

# ---------------------------------------------------------------------------
# Fail with wrong branch
# Requirements: 1.2, 1.3
# ---------------------------------------------------------------------------

@test "integration: falha com branch incorreta (refs/heads/feature-x)" {
  run_pipeline "v1" "false" "false" "refs/heads/feature-x" || true

  [ "$PIPELINE_STATUS" -ne 0 ]
  [[ "$PIPELINE_OUTPUT" == *"main"* ]]
}

@test "integration: falha com branch incorreta (refs/tags/v1)" {
  run_pipeline "v1" "false" "false" "refs/tags/v1" || true

  [ "$PIPELINE_STATUS" -ne 0 ]
  [[ "$PIPELINE_OUTPUT" == *"main"* ]]
}

# ---------------------------------------------------------------------------
# Fail with invalid tag format
# Requirements: 2.2, 2.3
# ---------------------------------------------------------------------------

@test "integration: falha com formato de tag inválido (v1.0)" {
  run_pipeline "v1.0" "false" "false" "refs/heads/main" || true

  [ "$PIPELINE_STATUS" -ne 0 ]
  [[ "$PIPELINE_OUTPUT" == *"vN"* ]]
}

@test "integration: falha com formato de tag inválido (1)" {
  run_pipeline "1" "false" "false" "refs/heads/main" || true

  [ "$PIPELINE_STATUS" -ne 0 ]
  [[ "$PIPELINE_OUTPUT" == *"vN"* ]]
}

@test "integration: falha com formato de tag inválido (V1 maiúsculo)" {
  run_pipeline "V1" "false" "false" "refs/heads/main" || true

  [ "$PIPELINE_STATUS" -ne 0 ]
  [[ "$PIPELINE_OUTPUT" == *"vN"* ]]
}

# ---------------------------------------------------------------------------
# Audit log fields present on successful create
# Requirements: 3.1 (audit log)
# ---------------------------------------------------------------------------

@test "integration: log de auditoria contém campos obrigatórios na criação" {
  local current_commit
  current_commit=$(git -C "$REPO_DIR" rev-parse HEAD)

  # Capture audit output directly (dry-run=true so we can inspect without side effects)
  local audit_out
  audit_out=$(env TAG_EXISTS=false DRY_RUN=false TAG_VERSION="v1" \
    CURRENT_COMMIT="$current_commit" PREVIOUS_COMMIT="" ACTOR="testuser" \
    bash "$AUDIT_LOG" 2>&1)

  [[ "$audit_out" == *"[AUDIT] Actor: testuser"* ]]
  [[ "$audit_out" == *"[AUDIT] Operation: CREATE"* ]]
  [[ "$audit_out" == *"[AUDIT] Tag: v1"* ]]
  [[ "$audit_out" == *"[AUDIT] Commit: $current_commit"* ]]
}

@test "integration: log de auditoria contém campos obrigatórios na recriação" {
  local current_commit="abc1234"
  local previous_commit="def5678"

  local audit_out
  audit_out=$(env TAG_EXISTS=true DRY_RUN=false TAG_VERSION="v1" \
    CURRENT_COMMIT="$current_commit" PREVIOUS_COMMIT="$previous_commit" ACTOR="testuser" \
    bash "$AUDIT_LOG" 2>&1)

  [[ "$audit_out" == *"[AUDIT] Actor: testuser"* ]]
  [[ "$audit_out" == *"[AUDIT] Operation: RECREATE"* ]]
  [[ "$audit_out" == *"[AUDIT] Tag: v1"* ]]
  [[ "$audit_out" == *"[AUDIT] Previous commit: $previous_commit"* ]]
  [[ "$audit_out" == *"[AUDIT] New commit: $current_commit"* ]]
}
