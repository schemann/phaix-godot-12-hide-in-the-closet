#!/usr/bin/env bash
# Runs every step's main scene headless for 120 frames (tools/smoke_run.gd) and fails on any ERROR,
# SCRIPT ERROR or WARNING line (the project treats a warning as a bug), then lists
# the GDScript warnings of every script (tools/check_warnings.py). smoke_run.gd frees the scene before
# the engine quits, so a sound that still plays is not reported as leaked (Godot issue 76745).
# Usage: tools/smoke_steps.sh   (from anywhere)
set -u
main() {   # the whole script is one function: bash parses it completely before running it, so an edit in the shared tree cannot break a running copy

project="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

for step_dir in "$project"/steps/step_*/; do
	step="$(basename "$step_dir")"
	log="$(godot --headless --path "$project" -s res://tools/smoke_run.gd -- "--scene=res://steps/$step/main.tscn" --frames=120 2>&1)"
	code=$?
	problems="$(printf '%s\n' "$log" | grep -E 'ERROR|WARNING' || true)"
	if [ "$code" -ne 0 ] || [ -n "$problems" ]; then
		echo "FAIL $step (exit $code)"
		printf '%s\n' "$problems" | sed 's/^/     /'
		failed=1
	else
		echo "PASS $step"
	fi
done

# GDScript warnings are only reported by the editor, so ask a headless editor.
if python3 -I "$project/tools/check_warnings.py" "$project"; then
	echo "PASS check_warnings: no GDScript error or warning in the project"
else
	echo "FAIL check_warnings"
	failed=1
fi

exit "$failed"
}
main "$@"; exit $?
