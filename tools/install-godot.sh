#!/usr/bin/env bash
# Install the Godot editor that .github/workflows/godot-checks.yml pins, for
# Linux machines and cloud agents. The release, binary and SHA-256 are read
# from the workflow, so the two can't drift. Running it again is cheap: if that
# version already runs at the install path, nothing is downloaded or installed.
#
# The install path is /usr/local/bin/godot, or $DEADWAX_GODOT when it is set
# (tools/deadwax.sh looks there first). Headless import and the test suites need
# only curl and unzip; the other packages let play, dev and the editor open a
# window with sound.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/godot-checks.yml"
INSTALL_PATH="${DEADWAX_GODOT:-/usr/local/bin/godot}"
PACKAGES=(ca-certificates curl unzip libdbus-1-3 libfontconfig1 libgl1 libx11-6
	libxcursor1 libxext6 libxi6 libxinerama1 libxrandr2 libxrender1)

die() {
	echo "$*" >&2
	exit 1
}

as_root() {
	if [[ "$(id -u)" -eq 0 ]]; then
		"$@"
	else
		sudo "$@"
	fi
}

workflow_value() {
	local value
	value="$(sed -n "s/^[[:space:]]*$1:[[:space:]]*//p" "$WORKFLOW" | head -n 1 | tr -d "\"'[:space:]")"
	[[ -n "$value" ]] || die "Could not read $1 from $WORKFLOW"
	printf '%s\n' "$value"
}

[[ -f "$WORKFLOW" ]] || die "Missing $WORKFLOW"
GODOT_RELEASE="$(workflow_value GODOT_RELEASE)"
GODOT_BINARY="$(workflow_value GODOT_BINARY)"
GODOT_SHA256="$(workflow_value GODOT_SHA256)"
# A 4.7.1-stable build reports itself as 4.7.1.stable.official.<commit>.
EXPECTED_VERSION="${GODOT_RELEASE/-/.}"

installed_version() {
	if [[ -x "$INSTALL_PATH" ]]; then
		"$INSTALL_PATH" --version 2>/dev/null | head -n 1 || true
	fi
}

current="$(installed_version)"
if [[ "$current" == "$EXPECTED_VERSION".* ]]; then
	echo "Godot $current is already installed at $INSTALL_PATH"
	exit 0
fi

# Install only the packages that are missing, so a prepared machine never needs
# the network for this step. A failure here only warns: headless runs need just
# curl and unzip, which are checked below.
if command -v apt-get >/dev/null 2>&1 && command -v dpkg >/dev/null 2>&1; then
	missing=()
	for package in "${PACKAGES[@]}"; do
		dpkg -s "$package" >/dev/null 2>&1 || missing+=("$package")
	done
	need_alsa=0
	dpkg -s libasound2t64 >/dev/null 2>&1 || dpkg -s libasound2 >/dev/null 2>&1 || need_alsa=1
	if (( ${#missing[@]} > 0 || need_alsa )); then
		export DEBIAN_FRONTEND=noninteractive
		if as_root apt-get update -qq; then
			if (( need_alsa )); then
				# Ubuntu 24.04 renamed ALSA's library in its 64-bit time transition.
				if apt-cache show libasound2t64 >/dev/null 2>&1; then
					missing+=(libasound2t64)
				else
					missing+=(libasound2)
				fi
			fi
			as_root apt-get install -y -qq --no-install-recommends "${missing[@]}" ||
				echo "Warning: could not install ${missing[*]}; windowed play may not start." >&2
		else
			echo "Warning: apt-get update failed; skipping system packages." >&2
		fi
	fi
else
	echo "No apt-get here: make sure curl and unzip are installed. Play and the editor also need X11, GL, fontconfig and ALSA libraries." >&2
fi
command -v curl >/dev/null 2>&1 || die "curl is required to download Godot."
command -v unzip >/dev/null 2>&1 || die "unzip is required to unpack Godot."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
archive="$work/${GODOT_BINARY}.zip"
url="https://github.com/godotengine/godot-builds/releases/download/${GODOT_RELEASE}/${GODOT_BINARY}.zip"
echo "Downloading $url"
curl --fail --location --retry 3 --output "$archive" "$url"
printf '%s  %s\n' "$GODOT_SHA256" "$archive" | sha256sum --check -
unzip -q "$archive" -d "$work"
[[ -f "$work/$GODOT_BINARY" ]] || die "The archive did not contain $GODOT_BINARY"

install_dir="$(dirname "$INSTALL_PATH")"
if mkdir -p "$install_dir" 2>/dev/null && [[ -w "$install_dir" ]]; then
	install -m 755 "$work/$GODOT_BINARY" "$INSTALL_PATH"
else
	as_root install -D -m 755 "$work/$GODOT_BINARY" "$INSTALL_PATH"
fi

current="$(installed_version)"
[[ "$current" == "$EXPECTED_VERSION".* ]] || die "Installed $INSTALL_PATH but it reports '$current', not $EXPECTED_VERSION."
echo "Installed Godot $current at $INSTALL_PATH"
