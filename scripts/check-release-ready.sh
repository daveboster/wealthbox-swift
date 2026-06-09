#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <tag>" >&2
    exit 1
fi

tag="$1"

if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-alpha\.[0-9]+)?$ ]]; then
    echo "error: tag must look like v0.1.0 or v0.1.0-alpha.1" >&2
    exit 1
fi

if [[ -n "$(git status --short)" ]]; then
    echo "error: working tree must be clean before release" >&2
    git status --short >&2
    exit 1
fi

version="${tag#v}"

if ! grep -q "## $version " CHANGELOG.md; then
    echo "error: CHANGELOG.md must contain a release heading for $version" >&2
    exit 1
fi

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/clang-module-cache}"

swift test
swift build
swift run wealthbox --help
