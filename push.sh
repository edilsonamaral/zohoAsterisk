#!/usr/bin/env bash
# push.sh — stage, commit, rebase, and push current branch
# Usage:
#   ./push.sh "Your commit message"
#   ./push.sh                # uses an auto WIP message
#   FORCE=1 ./push.sh "msg"  # force-with-lease push if needed

set -euo pipefail

# --- Helpers ---
die() { echo "Error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

# Ensure we're in a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a Git repository."

# Current branch
BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"
[ -n "${BRANCH}" ] || die "Detached HEAD; checkout a branch first."

# Remote
REMOTE="origin"
if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  die "Remote '$REMOTE' not found. Add it with: git remote add origin <URL>"
fi

# Commit message
MSG="${1:-Auto-commit $(date -Iseconds)}"

info "Repository: $(basename "$(git rev-parse --show-toplevel)")"
info "Branch: $BRANCH"
info "Remote: $REMOTE"

# Show brief status
git status -sb || true

# Stage everything and commit if there are changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  info "Staging changes…"
  git add -A

if git diff --cached --quiet >/dev/null; then
  info "Nothing to commit after staging."
else
  info "Committing: $MSG"
  git commit -m "$MSG"
fi
else
  info "No local changes to commit."
fi

# Fetch remote updates
info "Fetching $REMOTE…"
git fetch "$REMOTE"

# Ensure upstream is set
if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  info "Setting upstream to $REMOTE/$BRANCH"
  git branch --set-upstream-to="$REMOTE/$BRANCH" "$BRANCH" 2>/dev/null || true
fi

# Rebase on top of remote (with autostash in case something changed during hooks)
info "Rebasing on $REMOTE/$BRANCH (autostash)…"
git pull --rebase --autostash "$REMOTE" "$BRANCH"

# Push
if [ "${FORCE:-0}" = "1" ]; then
  info "Pushing with --force-with-lease…"
  git push --force-with-lease "$REMOTE" "$BRANCH"
else
  info "Pushing…"
  git push "$REMOTE" "$BRANCH"
fi

info "Done."
