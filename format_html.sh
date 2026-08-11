#!/usr/bin/env bash
# Formats all HTML files in a directory consistently using prettier,
# so that git diffs between snapshots reflect meaningful changes only.
#
# Usage: bash format_html.sh [dir]
#   dir  Directory containing HTML files to format (default: snapshot)
#
# Note: build snapshots without minification to ensure prettier can parse them:
#   zola -c /tmp/config_nomin.toml build --output-dir snapshot --force
# where /tmp/config_nomin.toml has `minify_html = false`
set -euo pipefail

DIR="${1:-snapshot}"

find "$DIR" -name "*.html" -print0 | xargs -0 npx --yes prettier@3 --parser html --write
