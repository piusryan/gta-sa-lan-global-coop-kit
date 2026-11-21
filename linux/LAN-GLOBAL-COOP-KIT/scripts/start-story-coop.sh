#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export WINEPREFIX="$DIR/.wine-prefix"
# Wine 11 uses a wow64 prefix; forcing WINEARCH=win32 makes Wine refuse to start.
unset WINEARCH
cd "$DIR"
exec wine gta_sa.exe "$@"
