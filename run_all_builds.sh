#!/bin/bash
# run_all_builds.sh - Execute build_stack_data.sh in all projects

set -e

# Find and execute all build_stack_data.sh scripts
find . -name "build_stack_data.sh" -type f | while read -r script; do
    dir=$(dirname "$script")
    echo "=== Running: $script ==="
    (cd "$dir" && ./build_stack_data.sh)
    echo ""
done

echo "Done."
