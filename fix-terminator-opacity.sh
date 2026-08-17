#!/usr/bin/env bash

set -e

echo "=========================================="
echo " Arch Clown - Terminator Opacity Fix"
echo "=========================================="

PICOM="$HOME/.config/picom/picom.conf"
TERMINATOR="$HOME/.config/terminator/config"

# --------------------------------------------------
# Check files
# --------------------------------------------------

if [[ ! -f "$PICOM" ]]; then
    echo "ERROR: Picom config not found:"
    echo "  $PICOM"
    exit 1
fi

if [[ ! -f "$TERMINATOR" ]]; then
    echo "WARNING: Terminator config not found:"
    echo "  $TERMINATOR"
fi

# --------------------------------------------------
# Backup
# --------------------------------------------------

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo
echo "[1/5] Creating backups..."

cp "$PICOM" "$PICOM.backup.$TIMESTAMP"

if [[ -f "$TERMINATOR" ]]; then
    cp "$TERMINATOR" "$TERMINATOR.backup.$TIMESTAMP"
fi

echo "Backups created."

# --------------------------------------------------
# Fix Picom opacity
# --------------------------------------------------

echo
echo "[2/5] Removing focus-based Terminator opacity..."

python3 - "$PICOM" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

# Remove existing Terminator opacity rules
pattern = re.compile(
    r'opacity-rule\s*=\s*\[\s*'
    r'"99:class_g\s*=\s*[\']Terminator[\']\s*&&\s*focused",\s*'
    r'"85:class_g\s*=\s*[\']Terminator[\']\s*&&\s*!focused",\s*'
    r'\];',
    re.MULTILINE
)

replacement = '''opacity-rule = [
  "100:class_g = 'Terminator'",
];'''

new_text, count = pattern.subn(replacement, text)

if count == 0:
    # If the exact original rule isn't found,
    # replace any existing opacity-rule block.
    generic = re.compile(
        r'opacity-rule\s*=\s*\[[\s\S]*?\];',
        re.MULTILINE
    )

    if generic.search(text):
        new_text = generic.sub(replacement, text, count=1)
    else:
        new_text = text.rstrip() + "\n\n" + replacement + "\n"

path.write_text(new_text)
PY

echo "Picom opacity rule fixed."

# --------------------------------------------------
# Fix Terminator transparency
# --------------------------------------------------

if [[ -f "$TERMINATOR" ]]; then

    echo
    echo "[3/5] Removing Terminator transparency..."

    python3 - "$TERMINATOR" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

# Remove transparent background settings
text = text.replace(
    "background_type = transparent",
    "background_type = solid"
)

text = text.replace(
    "background_darkness = 0.8\n",
    ""
)

# Remove placeholder background image
text = text.replace(
    "background_image = /change/me\n",
    ""
)

# Remove TerminatorThemes plugin
text = text.replace(
    ", TerminatorThemes",
    ""
)

text = text.replace(
    "TerminatorThemes, ",
    ""
)

text = text.replace(
    "TerminatorThemes",
    ""
)

# Add solid background if not already present
if "background_color =" not in text:
    text = text.replace(
        "[[default]]",
        "[[default]]\n    background_color = \"#000000\"",
        1
    )

path.write_text(text)
PY

    echo "Terminator transparency disabled."

else
    echo "Skipping Terminator config."
fi

# --------------------------------------------------
# Restart Picom
# --------------------------------------------------

echo
echo "[4/5] Restarting Picom..."

pkill picom 2>/dev/null || true

sleep 1

if command -v picom >/dev/null 2>&1; then
    picom \
        --config "$PICOM" \
        --backend xrender \
        --fade-in-step=1 \
        --fade-out-step=1 \
        --fade-delta=0 \
        >/dev/null 2>&1 &

    disown

    echo "Picom restarted."
else
    echo "WARNING: picom command not found."
fi

# --------------------------------------------------
# Show result
# --------------------------------------------------

echo
echo "[5/5] Checking Terminator opacity rule..."
echo

grep -A4 -B1 "opacity-rule" "$PICOM" || true

echo
echo "=========================================="
echo " FIX COMPLETED"
echo "=========================================="
echo
echo "Terminator should now remain:"
echo
echo "  Focused:    100% opaque"
echo "  Unfocused:  100% opaque"
echo
echo "Backups:"
echo "  $PICOM.backup.$TIMESTAMP"

if [[ -f "$TERMINATOR" ]]; then
    echo "  $TERMINATOR.backup.$TIMESTAMP"
fi

echo
echo "Test by:"
echo "  1. Open Terminator"
echo "  2. Click another window"
echo "  3. Click back on Terminator"
echo
echo "The opacity should no longer change."
echo
