#!/bin/bash
# Sync team code -> build container image (if needed) -> compile -> launch the simulator.
# Expects FTC2026/ and virtual_robot_ftc/ next to this script's directory (the "workspace").
# FTC2026/ is only READ here; this script never writes to it.
set -euo pipefail

TOOLS="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ROOT="${FTC_WORKSPACE:-$(dirname "$TOOLS")}"
SRC="$ROOT/FTC2026/TeamCode/src/main/java/org/firstinspires/ftc/teamcode"
SIM="$ROOT/virtual_robot_ftc"
DEST="$SIM/TeamCode/src/org/firstinspires/ftc/teamcode"
MANIFEST="$DEST/.synced_from_ftc2026"
IMAGE=virtual-robot-sim

# --- 1. Sync team OpModes into the simulator ---------------------------------------------------
echo "==> Syncing team code from $(git -C "$ROOT/FTC2026" branch --show-current)"
if [ -f "$MANIFEST" ]; then
    while IFS= read -r f; do rm -f "$DEST/$f"; done < "$MANIFEST"
fi
: > "$MANIFEST"
for f in "$SRC"/*.java; do
    name="$(basename "$f")"
    cp "$f" "$DEST/$name"
    echo "$name" >> "$MANIFEST"
    echo "    $name"
done

# --- 2. Container image (rebuilt when the Containerfile changes) -------------------------------
WANT="$(sha256sum "$TOOLS/sim/Containerfile" | cut -c1-16)"
HAVE="$(podman image inspect "$IMAGE" --format '{{index .Labels "containerfile-hash"}}' 2>/dev/null || true)"
if [ "$WANT" != "$HAVE" ]; then
    echo "==> Building container image"
    # Pull anonymously: a stale docker.io login in podman's auth file makes pulls fail with "unauthorized".
    NOAUTH="$(mktemp)"; echo '{}' > "$NOAUTH"
    podman build --authfile "$NOAUTH" --label "containerfile-hash=$WANT" -t "$IMAGE" \
        -f "$TOOLS/sim/Containerfile" "$TOOLS/sim"
    rm -f "$NOAUTH"
fi
[ "${1:-}" = "--build-only" ] && exit 0

# --- 3. Compile and launch inside the container -----------------------------------------------
echo "==> Starting container"
ARGS=(--rm --userns=keep-id --security-opt label=disable --hostname "$(hostname)"
      -e DISPLAY="${DISPLAY:-:0}" -v /tmp/.X11-unix:/tmp/.X11-unix
      -v "$SIM":/sim:rw
      -v "$TOOLS/sim/container-build-and-run.sh":/container-build-and-run.sh:ro)
[ -t 0 ] && ARGS+=(-it)
[ -e /dev/dri ] && ARGS+=(--device /dev/dri)
XA="${XAUTHORITY:-$HOME/.Xauthority}"
[ -f "$XA" ] && ARGS+=(-e XAUTHORITY=/tmp/.xauth -v "$XA":/tmp/.xauth:ro)
exec podman run "${ARGS[@]}" "$IMAGE" /container-build-and-run.sh
