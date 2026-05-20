#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-main}"

echo "== Claude Web update =="
echo "project: ${PROJECT_DIR}"
echo "remote:  ${REMOTE}/${BRANCH}"

if ! command -v git >/dev/null 2>&1; then
  echo "error: git command not found"
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: ${PROJECT_DIR} is not a git work tree"
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: local repository has uncommitted changes."
  echo "Please commit, stash, or back up local code changes before updating."
  echo "Runtime files such as .env, chat.db, uploads/, and logs/ are ignored and will be kept."
  exit 1
fi

echo "== fetch =="
git fetch "$REMOTE" "$BRANCH"

LOCAL_COMMIT="$(git rev-parse HEAD)"
REMOTE_COMMIT="$(git rev-parse "${REMOTE}/${BRANCH}")"
BASE_COMMIT="$(git merge-base HEAD "${REMOTE}/${BRANCH}")"

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
  echo "already up to date"
elif [ "$LOCAL_COMMIT" = "$BASE_COMMIT" ]; then
  echo "== fast-forward =="
  git merge --ff-only "${REMOTE}/${BRANCH}"
else
  echo "error: local branch has commits not on ${REMOTE}/${BRANCH}."
  echo "Please resolve manually, then run ./deploy.sh."
  exit 1
fi

echo "== deploy =="
./deploy.sh
