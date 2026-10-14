#!/usr/bin/env bash
# Export the web build into a folder (default: ../build/web). Needs Godot 4.3 and its export templates.
#   GODOT=/path/to/godot tools/export_web.sh [out_dir]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-../build/web}"
mkdir -p "$OUT"
"${GODOT:-godot}" --headless --path . --export-release "Web" "$(realpath "$OUT")/index.html"
echo "Exported to $OUT"
