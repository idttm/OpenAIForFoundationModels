#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
candidate_list="$(mktemp)"
trap 'rm -f "$candidate_list"' EXIT

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files --cached --others --exclude-standard -z >"$candidate_list"
else
  find . \
    \( -path './.git' -o -path './.build' -o -path './.derivedData' \
       -o -path './.swiftpm' -o -path './.grok' -o -path './.agents' \) -prune \
    -o -type f -print0 >"$candidate_list"
fi

check_pattern() {
  local description="$1"
  local pattern="$2"
  local found=0
  while IFS= read -r -d '' file; do
    if rg -n "$pattern" -- "$file"; then
      found=1
    fi
  done <"$candidate_list"
  if (( found != 0 )); then
    echo "error: ${description}" >&2
    fail=1
  fi
}

check_pattern "possible OpenAI API key" \
  'sk-(proj|svcacct)-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{40,}'
check_pattern "machine-specific absolute user path" \
  '/Users/[A-Za-z0-9._-]+/|/home/[A-Za-z0-9._-]+/|C:\\Users\\'
check_pattern "Apple Development Team identifier" \
  'DEVELOPMENT_TEAM = "[A-Z0-9]{6,}";'
check_pattern "unresolved merge conflict" '^(<<<<<<<|=======|>>>>>>>)'

while IFS= read -r -d '' file; do
  case "$file" in
    *.xcuserstate | */xcuserdata/* | */.DS_Store)
      echo "$file"
      echo "error: local Xcode or macOS user-state files are publishable" >&2
      fail=1
      ;;
  esac
done <"$candidate_list"

if (( fail != 0 )); then
  exit 1
fi

echo "Repository hygiene checks passed."
