#!/usr/bin/env bash
# tests/run_all.sh -- GDD 22. Run this before every build.
#
#   ./tests/run_all.sh                 # uses `godot` on PATH
#   GODOT=~/godot4 ./tests/run_all.sh  # or point it at your binary
#
# Each test scene is its own Godot process so that one crashing test cannot hide the
# others, and so a non-zero exit code is meaningful. parseall runs FIRST: if any script
# fails to compile, every other result is untrustworthy.

set -uo pipefail

GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

total=0
failed=0
failed_names=()

run_scene() {
	local scene="$1"
	total=$((total + 1))
	printf '\n\033[1m== %s\033[0m\n' "$scene"
	if "$GODOT" --headless --path "$ROOT" "res://$scene" 2>&1; then
		printf '   -> PASS\n'
	else
		printf '   -> \033[31mFAIL\033[0m\n'
		failed=$((failed + 1))
		failed_names+=("$scene")
	fi
}

run_scene "tests/parseall.tscn"
if [ "$failed" -ne 0 ]; then
	echo
	echo "parseall failed -- stopping. Fix the compile errors before reading any other result."
	exit 1
fi

shopt -s nullglob
for f in tests/test_*.tscn; do
	run_scene "${f#./}"
done
shopt -u nullglob

echo
echo "==============================================="
echo " $((total - failed))/$total test scenes passed"
if [ "$failed" -ne 0 ]; then
	echo " FAILED:"
	for n in "${failed_names[@]}"; do echo "   - $n"; done
	echo "==============================================="
	exit 1
fi
echo "==============================================="
exit 0
