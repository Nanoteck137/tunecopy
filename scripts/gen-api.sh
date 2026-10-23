#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REF="${PYRIN_REF:-main}"
BRANCH=""
TAG=""
PYRIN_JSON_URL="${PYRIN_JSON_URL:-}"
PYRIN_JSON_FILE="${PYRIN_JSON_FILE:-misc/pyrin.json}"
OUTPUT_DIR="${OUTPUT_DIR:-api}"

usage() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS] [REF]

Download misc/pyrin.json from Nanoteck137/tunebook and generate the Golang API client.

REF can be a branch, tag, or commit. Defaults to "$REF".

Options:
  -r, --ref REF       Branch, tag, or commit to download from
  -b, --branch NAME   Use a branch (same as --ref)
  -t, --tag NAME      Use a tag (same as --ref)
  -f, --file PATH     Local path for the downloaded file (default: $PYRIN_JSON_FILE)
  -o, --output DIR    Output directory for generated code (default: $OUTPUT_DIR)
  -u, --url URL       Override the download URL (ignores the ref)
  -h, --help          Show this help

Environment variables:
  PYRIN_REF, PYRIN_JSON_FILE, PYRIN_JSON_URL, OUTPUT_DIR

Examples:
  $(basename "$0")                  # main branch
  $(basename "$0") 0.19.0           # tag
  $(basename "$0") --tag 0.19.0     # tag
  $(basename "$0") --branch main    # branch
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-r|--ref)
			REF="${2:?missing value for $1}"
			shift 2
			;;
		-b|--branch)
			BRANCH="${2:?missing value for $1}"
			shift 2
			;;
		-t|--tag)
			TAG="${2:?missing value for $1}"
			shift 2
			;;
		-f|--file)
			PYRIN_JSON_FILE="${2:?missing value for $1}"
			shift 2
			;;
		-o|--output)
			OUTPUT_DIR="${2:?missing value for $1}"
			shift 2
			;;
		-u|--url)
			PYRIN_JSON_URL="${2:?missing value for $1}"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			;;
		-*)
			echo "error: unknown option: $1" >&2
			usage >&2
			exit 1
			;;
		*)
			REF="$1"
			shift
			;;
	esac
done

if [ -n "$BRANCH" ] && [ -n "$TAG" ]; then
	echo "error: --branch and --tag cannot be used together" >&2
	exit 1
fi

if [ -n "$BRANCH" ]; then
	REF="$BRANCH"
fi

if [ -n "$TAG" ]; then
	REF="$TAG"
fi

if [ -z "$PYRIN_JSON_URL" ]; then
	PYRIN_JSON_URL="https://raw.githubusercontent.com/Nanoteck137/tunebook/${REF}/misc/pyrin.json"
fi

if ! command -v pyrin >/dev/null 2>&1; then
	echo "error: pyrin was not found in PATH" >&2
	echo "hint: run this script inside the project dev shell (direnv allow / nix develop)" >&2
	exit 1
fi

mkdir -p "$(dirname "$PYRIN_JSON_FILE")" "$OUTPUT_DIR"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

echo "Downloading $PYRIN_JSON_URL"
if ! curl -fsSL --retry 3 "$PYRIN_JSON_URL" -o "$tmp_file"; then
	echo "error: failed to download $PYRIN_JSON_URL (does ref '$REF' exist?)" >&2
	exit 1
fi

if [ ! -s "$tmp_file" ]; then
	echo "error: downloaded file is empty" >&2
	exit 1
fi

mv "$tmp_file" "$PYRIN_JSON_FILE"
chmod 644 "$PYRIN_JSON_FILE"

echo "Generating Golang API client in $OUTPUT_DIR"
pyrin gen go "$PYRIN_JSON_FILE" -o "$OUTPUT_DIR"
