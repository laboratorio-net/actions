#!/usr/bin/env bats
# Property test: tag points to HEAD
# Property 3: For any successful tag operation, the resulting tag must point to HEAD
# Tag: Feature: tag-management-workflow, Property 3: tag points to HEAD
# Validates: Requirements 3.1, 4.3

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

@test "Property 3: CREATE - tag points to HEAD (100 iterations with different commits)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"

    # Make a new commit to vary HEAD
    echo "iteration $i" > "$TMPDIR/file.txt"
    git -C "$TMPDIR" add file.txt
    git -C "$TMPDIR" commit -q -m "Commit $i"

    local head
    head=$(git -C "$TMPDIR" rev-parse HEAD)

    # Simulate step 8: git tag
    git -C "$TMPDIR" tag "$tag"

    local tag_commit
    tag_commit=$(git -C "$TMPDIR" rev-parse "$tag")

    [ "$tag_commit" = "$head" ] || {
      echo "FAILED: tag $tag points to $tag_commit but HEAD is $head" >&2
      return 1
    }

    # Clean up tag for next iteration
    git -C "$TMPDIR" tag -d "$tag" > /dev/null
  done
}

@test "Property 3: RECREATE - tag points to new HEAD after recreation (100 iterations)" {
  for i in $(seq 1 100); do
    local n=$(( RANDOM % 1000 + 1 ))
    local tag="v${n}"

    # First commit and tag (old state)
    echo "old $i" > "$TMPDIR/old.txt"
    git -C "$TMPDIR" add old.txt
    git -C "$TMPDIR" commit -q -m "Old commit $i"
    git -C "$TMPDIR" tag "$tag"

    # New commit (new HEAD)
    echo "new $i" > "$TMPDIR/new.txt"
    git -C "$TMPDIR" add new.txt
    git -C "$TMPDIR" commit -q -m "New commit $i"

    local new_head
    new_head=$(git -C "$TMPDIR" rev-parse HEAD)

    # Simulate steps 7+8: delete old tag, create new tag at HEAD
    git -C "$TMPDIR" tag -d "$tag" > /dev/null
    git -C "$TMPDIR" tag "$tag"

    local tag_commit
    tag_commit=$(git -C "$TMPDIR" rev-parse "$tag")

    [ "$tag_commit" = "$new_head" ] || {
      echo "FAILED: recreated tag $tag points to $tag_commit but new HEAD is $new_head" >&2
      return 1
    }

    # Clean up
    git -C "$TMPDIR" tag -d "$tag" > /dev/null
  done
}
