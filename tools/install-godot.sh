#!/usr/bin/env bash
# Install the Godot 4.7.1 Linux editor pinned by the GitHub checks workflow.
# Idempotent: a matching binary at /usr/local/bin/godot skips the download.
set -euo pipefail

GODOT_RELEASE="4.7.1-stable"
GODOT_BINARY="Godot_v4.7.1-stable_linux.x86_64"
GODOT_SHA256="c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba"
INSTALL_PATH="/usr/local/bin/godot"

if [[ "$(id -u)" -eq 0 ]]; then
	SUDO=()
else
	SUDO=(sudo)
fi

export DEBIAN_FRONTEND=noninteractive
"${SUDO[@]}" apt-get update -qq
"${SUDO[@]}" apt-get install -y -qq --no-install-recommends \
	ca-certificates \
	curl \
	unzip \
	libasound2t64 \
	libdbus-1-3 \
	libfontconfig1 \
	libgl1 \
	libx11-6 \
	libxcursor1 \
	libxext6 \
	libxi6 \
	libxinerama1 \
	libxrandr2 \
	libxrender1

if [[ -x "$INSTALL_PATH" ]] && "$INSTALL_PATH" --version 2>/dev/null | grep -q '^4\.7\.1\.'; then
	echo "Godot 4.7.1 already installed at $INSTALL_PATH"
	"$INSTALL_PATH" --version
	exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
archive="$work/${GODOT_BINARY}.zip"
curl --fail --location --retry 3 --output "$archive" \
	"https://github.com/godotengine/godot-builds/releases/download/${GODOT_RELEASE}/${GODOT_BINARY}.zip"
printf '%s  %s\n' "$GODOT_SHA256" "$archive" | sha256sum --check -
unzip -q "$archive" -d "$work"
"${SUDO[@]}" install -m 755 "$work/$GODOT_BINARY" "$INSTALL_PATH"
"$INSTALL_PATH" --version
