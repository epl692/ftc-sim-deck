# ftc-sim-deck

Runs the [virtual_robot](https://github.com/epl692/virtual_robot_ftc) FTC simulator in a podman container, with the latest team code from FRCTeam107/FTC2026 synced in. Built for the Steam Deck (works on any Linux box with podman, git and an X11/XWayland display).

## Install (Steam Deck, desktop mode, once)

    curl -fsSL https://raw.githubusercontent.com/epl692/ftc-sim-deck/main/install.sh | bash

This clones everything into `~/ftc-sim`, builds the container image, and adds an **FTC Simulator** launcher to the desktop, the app menu and (via `steamos-add-to-steam`) the Steam library for game mode.

## Use

Launch **FTC Simulator**. Every launch pulls the newest tools, simulator and team code (offline launches use the last copy), then compiles and starts the sim. Log: `~/ftc-sim/last-run.log`.

Pick another branch in `~/ftc-sim/ftc-sim.conf` (`TEAM_BRANCH`, `SIM_BRANCH`). The copies under `~/ftc-sim` are reset to GitHub on every launch, so don't edit them there.

## Development machine

`run-sim.sh` expects `FTC2026/` and `virtual_robot_ftc/` next to this directory and never writes to `FTC2026/`. `deck-launch.sh` and `install.sh` are Deck-only (they hard-reset the checkouts).
