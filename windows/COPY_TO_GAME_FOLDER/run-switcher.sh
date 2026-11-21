#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
if command -v python3 >/dev/null 2>&1; then
    exec python3 switch_network_mode.py
fi
exec python switch_network_mode.py
