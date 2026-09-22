#!/usr/bin/env bash
# Linux entry point for the same doctor/check/test flow as tools/deadwax.ps1.
set -euo pipefail

ACTION="${1:-doctor}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIRED_SERIES="4.7"

SUITES=(
	smoke_test
	save_store_test
	campaign_test
	tonearm_test
	overture_test
	sprite_animation_test
	residents_test
	economy_state_test
	economy_test
	scenery_test
	lighting_test
	attack_feel_test
	gui_animation_test
	map_item_test
	gather_reward_test
	gather_route_test
	loft_voice_test
	home_song_test
	opening_cutscene_test
	opening_audio_test
	yard_voice_test
	yard_audio_test
	combo_test
	practice_room_test
	combo_readability_test
	street_looper_test
	unplayed_test
	discoveries_test
	echo_audio_test
	collection_state_test
	echo_trial_test
	collection_book_test
	collection_test
	abilities_state_test
	abilities_test
	ability_world_test
	ability_book_test
	walk_test
	exploration_state_test
	exploration_test
	exploration_world_test
	exploration_map_test
)

resolve_godot() {
	if [[ -n "${DEADWAX_GODOT:-}" && -x "$DEADWAX_GODOT" ]]; then
		printf '%s\n' "$DEADWAX_GODOT"
		return
	fi
	if command -v godot >/dev/null 2>&1; then
		command -v godot
		return
	fi
	echo "Godot was not found. Run bash tools/install-godot.sh or set DEADWAX_GODOT." >&2
	exit 1
}

require_godot_series() {
	local executable="$1"
	local version
	version="$("$executable" --version | head -n 1 | tr -d '[:space:]')"
	if [[ "$version" != ${REQUIRED_SERIES}* ]]; then
		echo "Dead Wax requires Godot ${REQUIRED_SERIES}.x; found $version" >&2
		exit 1
	fi
	printf '%s\n' "$version"
}

run_godot() {
	local executable="$1"
	shift
	"$executable" "$@"
}

show_help() {
	cat <<'EOF'
Dead Wax developer commands (Linux)

  bash tools/deadwax.sh doctor  Check Godot, Git, and repository state.
  bash tools/deadwax.sh check   Import resources, then run all native test suites.
  bash tools/deadwax.sh test    Run all native test suites without importing.

Windows play, editor, dev, and vibe commands stay on deadwax.cmd.
The DEADWAX_GODOT environment variable can override Godot discovery.
EOF
}

case "$ACTION" in
	help|-h|--help)
		show_help
		;;
	doctor)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		echo "Project : $ROOT"
		echo "Godot   : $version ($godot)"
		echo "Git     : $(git --version)"
		echo "Status  :"
		git -C "$ROOT" status --short --branch
		;;
	test)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		echo "Running Dead Wax smoke tests with Godot $version"
		for suite in "${SUITES[@]}"; do
			run_godot "$godot" --headless --path "$ROOT" --script "res://tests/${suite}.gd"
		done
		;;
	check)
		godot="$(resolve_godot)"
		version="$(require_godot_series "$godot")"
		echo "Importing Dead Wax resources with Godot $version"
		run_godot "$godot" --headless --path "$ROOT" --import
		echo "Running native smoke tests"
		for suite in "${SUITES[@]}"; do
			run_godot "$godot" --headless --path "$ROOT" --script "res://tests/${suite}.gd"
		done
		;;
	*)
		echo "Unknown action '$ACTION'. Run: bash tools/deadwax.sh help" >&2
		exit 1
		;;
esac
