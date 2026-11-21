#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$DIR"/*.sh
mkdir -p "$DIR/.wine-prefix"
command -v wine
wine --version
