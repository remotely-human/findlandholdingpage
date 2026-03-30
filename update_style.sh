#!/usr/bin/env bash
# ============================================================
#  update_style.sh
#  Replaces the embedded Mapbox style in index.html with the
#  latest style exported from Mapbox Studio.
#
#  Usage:
#    ./update_style.sh                          # uses findland_background_style.zip
#    ./update_style.sh path/to/new_style.zip   # use a specific zip file
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML="$SCRIPT_DIR/index.html"
STYLE_DIR="$SCRIPT_DIR/findland_background_style"
STYLE_JSON="$STYLE_DIR/style.json"

# ── Determine zip source ──────────────────────────────────
if [[ $# -ge 1 ]]; then
  ZIP="$1"
else
  ZIP="$SCRIPT_DIR/findland_background_style.zip"
fi

if [[ ! -f "$ZIP" ]]; then
  echo "❌  Zip not found: $ZIP"
  echo "    Drop your Mapbox Studio export as 'findland_background_style.zip'"
  echo "    in the project folder, or pass the path as an argument."
  exit 1
fi

# ── Extract zip into style folder ────────────────────────
echo "📦  Extracting $ZIP …"
rm -rf "$STYLE_DIR"
unzip -q "$ZIP" -d "$STYLE_DIR"

if [[ ! -f "$STYLE_JSON" ]]; then
  echo "❌  style.json not found inside the zip. Is this a valid Mapbox Studio export?"
  exit 1
fi

# ── Inject style into index.html via Python ──────────────
echo "🗺   Injecting style into index.html …"
python3 - "$STYLE_JSON" "$HTML" << 'PYEOF'
import sys, json, re

style_path, html_path = sys.argv[1], sys.argv[2]

with open(style_path) as f:
    style_json = json.dumps(json.load(f), separators=(',', ':'))

with open(html_path) as f:
    html = f.read()

pattern = r'const STYLE = \{.*?\};'
if not re.search(pattern, html, re.DOTALL):
    print("❌  Could not locate 'const STYLE = {...};' in index.html")
    sys.exit(1)

new_html = re.sub(pattern, f'const STYLE = {style_json};', html, flags=re.DOTALL)

with open(html_path, 'w') as f:
    f.write(new_html)

print("✅  Style updated successfully")
PYEOF

# ── Rename zip to canonical name (unless already correct) ─
CANONICAL_ZIP="$SCRIPT_DIR/findland_background_style.zip"
if [[ "$(realpath "$ZIP")" != "$(realpath "$CANONICAL_ZIP" 2>/dev/null || echo '')" ]]; then
  cp "$ZIP" "$CANONICAL_ZIP"
  echo "📁  Zip saved as findland_background_style.zip"
fi

echo "🏰  Done. Reload index.html in your browser to see the new style."
