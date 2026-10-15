#!/bin/bash
# One-time setup for the Steam Deck (run in desktop mode):
#   curl -fsSL https://raw.githubusercontent.com/epl692/ftc-sim-deck/main/install.sh | bash
# Safe to re-run: it updates everything.
set -euo pipefail

HOME_DIR="${FTC_SIM_HOME:-$HOME/ftc-sim}"
TOOLS_REPO="${FTC_TOOLS_REPO:-https://github.com/epl692/ftc-sim-deck.git}"

command -v podman >/dev/null || { echo "podman is required but not installed."; exit 1; }
command -v git >/dev/null || { echo "git is required but not installed."; exit 1; }

mkdir -p "$HOME_DIR"
if [ -d "$HOME_DIR/tools/.git" ]; then
    git -C "$HOME_DIR/tools" pull --ff-only
else
    git clone "$TOOLS_REPO" "$HOME_DIR/tools"
fi
TOOLS="$HOME_DIR/tools"

[ -f "$HOME_DIR/ftc-sim.conf" ] || cp "$TOOLS/ftc-sim.conf" "$HOME_DIR/ftc-sim.conf"

# Fetch the team code and simulator, then build the container image now so game-mode launches are fast.
FTC_SIM_HOME="$HOME_DIR" "$TOOLS/deck-launch.sh" --build-only

# Launcher
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
DESKTOP_DIR="${DESKTOP_DIR:-$HOME/Desktop}"
mkdir -p "$DATA/applications" "$DATA/icons"
cp "$TOOLS/ftc-sim.png" "$DATA/icons/ftc-sim.png"
DESKTOP="$DATA/applications/ftc-sim.desktop"
sed -e "s|@TOOLS@|$TOOLS|g" -e "s|@ICON@|$DATA/icons/ftc-sim.png|g" "$TOOLS/ftc-sim.desktop" > "$DESKTOP"
chmod +x "$DESKTOP"
if [ -d "$DESKTOP_DIR" ]; then cp "$DESKTOP" "$DESKTOP_DIR/ftc-sim.desktop"; chmod +x "$DESKTOP_DIR/ftc-sim.desktop"; fi

# Show up in game mode's library
if command -v steamos-add-to-steam >/dev/null; then
    steamos-add-to-steam "$DESKTOP" || echo "Could not add to Steam automatically: right-click the desktop icon > Add to Steam."
else
    echo "To use it in game mode: in Steam (desktop mode) choose Games > Add a Non-Steam Game and pick 'FTC Simulator'."
fi
echo "Done. Launch 'FTC Simulator' from the desktop, the app menu, or the Steam library."
