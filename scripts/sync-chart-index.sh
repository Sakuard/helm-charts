#!/usr/bin/env bash
set -euo pipefail

# Use the uploaded archive so retries preserve the release's actual checksum.
version=$(awk '$1 == "version:" { print $2; exit }' common/Chart.yaml | tr -d '"')
tag="common-${version}"
temporary_dir=$(mktemp -d)
trap 'rm -rf "$temporary_dir"' EXIT

gh release download "$tag" --repo "$GITHUB_REPOSITORY" \
  --pattern "${tag}.tgz" --dir "$temporary_dir/packages"
git fetch origin gh-pages
git worktree add --detach "$temporary_dir/pages" origin/gh-pages
trap 'git worktree remove --force "$temporary_dir/pages"; rm -rf "$temporary_dir"' EXIT

merge_args=()
if [[ -f "$temporary_dir/pages/index.yaml" ]]; then
  merge_args=(--merge "$temporary_dir/pages/index.yaml")
fi
helm repo index "$temporary_dir/packages" \
  --url "https://github.com/${GITHUB_REPOSITORY}/releases/download/${tag}" \
  "${merge_args[@]}"
cp "$temporary_dir/packages/index.yaml" "$temporary_dir/pages/index.yaml"
git -C "$temporary_dir/pages" add index.yaml
if ! git -C "$temporary_dir/pages" diff --cached --quiet; then
  git -C "$temporary_dir/pages" commit -m "fix: synchronize ${tag} release index"
  git -C "$temporary_dir/pages" push origin HEAD:gh-pages
fi
