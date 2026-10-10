#!/usr/bin/env bash
# Linux counterpart of deadwax.cmd (tools/deadwax.ps1), for Linux machines and
# cloud agents. `check` and `test` run the suite list read from
# tools/deadwax.ps1, in its order with the canon suite first, so there is one
# list to maintain. Install the pinned Godot with tools/install-godot.sh.
set -euo pipefail

ACTION="${1:-doctor}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PS1_SCRIPT="$ROOT/tools/deadwax.ps1"
REQUIRED_SERIES="4.7"
SUITES=()

die() {
	echo "$*" >&2
	exit 1
}

resolve_godot() {
	if [[ -n "${DEADWAX_GODOT:-}" && -x "$DEADWAX_GODOT" ]]; then
		printf '%s\n' "$DEADWAX_GODOT"
		return
	fi
	local name
	for name in godot godot4; do
		if command -v "$name" >/dev/null 2>&1; then
			command -v "$name"
			return
		fi
	done
	die "Godot was not found. Run bash tools/install-godot.sh or set DEADWAX_GODOT."
}

require_godot_series() {
	local executable="$1"
	local version
	version="$("$executable" --version 2>/dev/null | head -n 1 | tr -d '[:space:]')" || true
	[[ "$version" == "$REQUIRED_SERIES".* ]] || die "Dead Wax requires Godot ${REQUIRED_SERIES}.x; found '${version}' at $executable"
	printf '%s\n' "$version"
}

# deadwax.cmd's suites. Both of its lists (test and check) must agree, and
# every listed suite must exist.
load_suites() {
	[[ -f "$PS1_SCRIPT" ]] || die "Missing $PS1_SCRIPT"
	local lists
	# shellcheck disable=SC2016 # $suite is PowerShell's variable, matched literally.
	lists="$(sed -n 's/.*foreach (\$suite in @(\([^)]*\))).*/\1/p' "$PS1_SCRIPT" | tr -d "' ")"
	[[ -n "$lists" ]] || die "No suite list found in tools/deadwax.ps1"
	if [[ "$(printf '%s\n' "$lists" | sort -u | wc -l)" -ne 1 ]]; then
		die "The test and check suite lists in tools/deadwax.ps1 differ; make them match."
	fi
	IFS=',' read -r -a SUITES <<< "$(printf '%s\n' "$lists" | head -n 1)"
	local suite
	for suite in "${SUITES[@]}"; do
		[[ "$suite" =~ ^[a-z0-9_]+$ ]] || die "tools/deadwax.ps1 lists an unexpected suite name: '$suite'"
		[[ -f "$ROOT/tests/$suite.gd" ]] || die "tools/deadwax.ps1 lists tests/$suite.gd, which doesn't exist."
	done
	(( ${#SUITES[@]} > 0 )) || die "tools/deadwax.ps1 lists no suites"
}

run_suites() {
	local godot="$1"
	local suite
	for suite in "${SUITES[@]}"; do
		if ! "$godot" --headless --path "$ROOT" --script "res://tests/${suite}.gd"; then
			die "FAILED: tests/${suite}.gd"
		fi
	done
	echo "All ${#SUITES[@]} suites passed."
}

show_help() {
	cat <<'EOF'
Dead Wax developer commands (Linux)

  bash tools/deadwax.sh doctor  Check Godot, Git, the suite list and repository state.
  bash tools/deadwax.sh play    Run the campaign with a runtime log in .godot/.
  bash tools/deadwax.sh dev     Open the mechanics rooms and planned-world tools.
  bash tools/deadwax.sh editor  Open the project in the Godot editor.
  bash tools/deadwax.sh check   Import resources, then run every test suite.
  bash tools/deadwax.sh test    Run every test suite without importing.

bash tools/install-godot.sh installs the Godot that CI pins. DEADWAX_GODOT
overrides Godot discovery. Mistral Vibe stays on deadwax.cmd.
EOF
}

case "$ACTION" in
	help|-h|--help)
		show_help
		;;
	doctor)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		load_suites
		echo "Project : $ROOT"
		echo "Godot   : $version ($godot)"
		echo "Git     : $(git --version)"
		echo "Suites  : ${#SUITES[@]} from tools/deadwax.ps1, ${SUITES[0]} first"
		echo "Status  :"
		git -C "$ROOT" status --short --branch
		;;
	test)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		load_suites
		echo "Running ${#SUITES[@]} Dead Wax test suites with Godot $version"
		run_suites "$godot"
		;;
	check)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		load_suites
		echo "Importing Dead Wax resources with Godot $version"
		"$godot" --headless --path "$ROOT" --import || die "The import failed."
		echo "Running ${#SUITES[@]} Dead Wax test suites"
		run_suites "$godot"
		;;
	play)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		mkdir -p "$ROOT/.godot"
		log="$ROOT/.godot/deadwax-play.log"
		echo "Starting Dead Wax with Godot $version"
		echo "Runtime log: $log"
		exec "$godot" --path "$ROOT" --log-file "$log"
		;;
	dev)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		echo "Opening the development rooms with Godot $version"
		exec "$godot" --path "$ROOT" -- --dev-rooms
		;;
	editor)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		echo "Opening Dead Wax in Godot $version"
		exec "$godot" --editor --path "$ROOT"
		;;
	*)
		die "Unknown action '$ACTION'. Run: bash tools/deadwax.sh help"
		;;
esac
