#!/bin/bash
# What the Steam Deck launcher runs: update everything from GitHub, then start the simulator.
# Layout: ~/ftc-sim/{tools,FTC2026,virtual_robot_ftc,ftc-sim.conf,last-run.log}
set -uo pipefail

HOME_DIR="${FTC_SIM_HOME:-$HOME/ftc-sim}"
TOOLS="$HOME_DIR/tools"
LOG="$HOME_DIR/last-run.log"
exec > >(tee "$LOG") 2>&1

TEAM_REPO=https://github.com/FRCTeam107/FTC2026.git
TEAM_BRANCH=main
SIM_REPO=https://github.com/epl692/virtual_robot_ftc.git
SIM_BRANCH=master
[ -f "$HOME_DIR/ftc-sim.conf" ] && . "$HOME_DIR/ftc-sim.conf"

fail() {
    echo "ERROR: $*"
    if command -v zenity >/dev/null; then zenity --error --no-markup --text="$* (see $LOG)" 2>/dev/null
    elif command -v kdialog >/dev/null; then kdialog --error "$* (see $LOG)" 2>/dev/null; fi
    exit 1
}

# Make a checkout match origin/<branch> exactly. Safe because nobody edits these copies on the Deck.
update() {  # dir url branch
    local dir="$1" url="$2" branch="$3"
    [ -d "$dir/.git" ] || git clone "$url" "$dir" || return 1
    if git -C "$dir" fetch --quiet origin "$branch"; then
        git -C "$dir" checkout --quiet -B "$branch" "origin/$branch" && git -C "$dir" reset --quiet --hard "origin/$branch"
    else
        echo "WARNING: could not update $dir (offline?). Using the existing copy."
    fi
}

# Update the tools themselves first; restart this script if it changed.
if [ -z "${FTC_SIM_RELAUNCHED:-}" ]; then
    before="$(git -C "$TOOLS" rev-parse HEAD 2>/dev/null)"
    git -C "$TOOLS" pull --ff-only --quiet || echo "WARNING: could not update tools (offline?)."
    if [ "$before" != "$(git -C "$TOOLS" rev-parse HEAD 2>/dev/null)" ]; then
        export FTC_SIM_RELAUNCHED=1
        exec "$TOOLS/deck-launch.sh" "$@"
    fi
fi

update "$HOME_DIR/FTC2026" "$TEAM_REPO" "$TEAM_BRANCH" || fail "Could not get the team code (first run needs internet)."
update "$HOME_DIR/virtual_robot_ftc" "$SIM_REPO" "$SIM_BRANCH" || fail "Could not get the simulator (first run needs internet)."

echo "==> Team code: $(git -C "$HOME_DIR/FTC2026" log -1 --format='%h %s')"
FTC_WORKSPACE="$HOME_DIR" "$TOOLS/run-sim.sh" "$@" || fail "The simulator stopped with an error."
