#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <target-file-path>" >&2
  exit 1
fi

target_input="$1"
if [[ ! -e "$target_input" ]]; then
  echo "[ERROR] File not found: $target_input" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "[ERROR] Not inside a git repository." >&2
  exit 1
fi

target_abs="$(cd "$(dirname "$target_input")" && pwd)/$(basename "$target_input")"
case "$target_abs" in
  "$repo_root"/*) ;;
  *)
    echo "[ERROR] Target must be inside repository: $repo_root" >&2
    exit 1
    ;;
esac

target_rel="${target_abs#"$repo_root"/}"
file_name="$(basename "$target_rel")"
base_no_ext="${file_name%.md}"
if [[ -z "$base_no_ext" ]]; then
  base_no_ext="$file_name"
fi

dir_rel="$(dirname "$target_rel")"
if [[ "$dir_rel" == "." ]]; then
  summary_rel="${base_no_ext}.summary.md"
else
  summary_rel="${dir_rel}/${base_no_ext}.summary.md"
fi
summary_abs="$repo_root/$summary_rel"

safe_base="$(printf '%s' "$base_no_ext" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
if [[ -z "$safe_base" ]]; then
  safe_base="summary"
fi

timestamp="$(TZ=Asia/Tokyo date +%Y%m%d%H%M%S)"
branch_name="codex/summarize-${safe_base}-${timestamp}"
pr_title="fix(docs): ${file_name} translations"

shell_quote() {
  printf '%q' "$1"
}

{
  echo "export TARGET_REL=$(shell_quote "$target_rel")"
  echo "export FILE_NAME=$(shell_quote "$file_name")"
  echo "export SUMMARY_REL=$(shell_quote "$summary_rel")"
  echo "export SUMMARY_ABS=$(shell_quote "$summary_abs")"
  echo "export BRANCH_NAME=$(shell_quote "$branch_name")"
  echo "export PR_TITLE=$(shell_quote "$pr_title")"
} 
