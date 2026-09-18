#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HAMMERSPOON_APP="/Applications/Hammerspoon.app"
HS_DIR="$HOME/.hammerspoon"
SPOONS_DIR="$HS_DIR/Spoons"
INIT_FILE="$HS_DIR/init.lua"
START_MARKER="-- >>> Post installer >>>"
END_MARKER="-- <<< Post installer <<<"

printf "\nInstalling Post...\n\n"

if [ ! -d "$HAMMERSPOON_APP" ]; then
  echo "Hammerspoon is not installed."
  echo "Opening the official Releases page..."
  open "https://github.com/Hammerspoon/hammerspoon/releases"
  echo
  echo "Install Hammerspoon first, then run Install Post.command again."
  read -n 1 -s -r -p "Press any key to close..."
  echo
  exit 1
fi

mkdir -p "$SPOONS_DIR"
rm -rf "$SPOONS_DIR/Post.spoon"
cp -R "$SCRIPT_DIR/Post.spoon" "$SPOONS_DIR/Post.spoon"

mkdir -p "$HS_DIR"
touch "$INIT_FILE"

# Backup current config before changing it
if [ -s "$INIT_FILE" ]; then
  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  cp "$INIT_FILE" "$INIT_FILE.post-backup-$TIMESTAMP"
fi

# Remove all older Post installer blocks, then write exactly one clean block
TMP_FILE="$(mktemp)"
awk -v start="$START_MARKER" -v end="$END_MARKER" '
  $0 == start { skipping = 1; next }
  $0 == end   { skipping = 0; next }
  !skipping   { print }
' "$INIT_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$INIT_FILE"

cat >> "$INIT_FILE" <<'BLOCK'

-- >>> Post installer >>>
hs.loadSpoon("Post")

spoon.Post:bindHotkeys({
    show = {{"alt"}, "D"}
})
-- <<< Post installer <<<
BLOCK

# Restart Hammerspoon so the new config loads immediately
osascript -e 'tell application "Hammerspoon" to quit' >/dev/null 2>&1 || true
sleep 1
open -a Hammerspoon

printf "\nPost installed.\n\n"
echo "Press Option + D to open Post."
echo "The first time it opens, choose your Markdown storage folder."
echo
echo "To change the storage folder later, delete ~/.hammerspoon/Post.storage"
echo "Then press Option + D and choose a new folder."
echo
read -n 1 -s -r -p "Press any key to close..."
echo
