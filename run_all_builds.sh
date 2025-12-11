#!/bin/bash
# run_all_builds.sh - Execute build_stack_data.sh in all projects
# Loops through project directories and runs build_stack_data.sh if it exists

set -e

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
DRY_RUN_FLAG=""
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN_FLAG="--dry-run"
    echo "========================================"
    echo "DRY RUN MODE - No directories will be created"
    echo "========================================"
    echo ""
fi

# Counter variables
total_found=0
total_executed=0
total_errors=0

echo "Scanning for build_stack_data.sh scripts..."
echo ""

# Loop through all subdirectories
for project_dir in "$SCRIPT_DIR"/*; do
    # Skip if not a directory
    [ -d "$project_dir" ] || continue

    # Get project name
    project_name=$(basename "$project_dir")

    # Check for build_stack_data.sh
    build_script="$project_dir/build_stack_data.sh"

    if [ -f "$build_script" ] && [ -x "$build_script" ]; then
        total_found=$((total_found + 1))
        echo "----------------------------------------"
        echo "[$total_found] Running: $project_name/build_stack_data.sh"
        echo "----------------------------------------"

        # Execute the script
        if cd "$project_dir" && ./build_stack_data.sh $DRY_RUN_FLAG; then
            total_executed=$((total_executed + 1))
            echo ""
        else
            total_errors=$((total_errors + 1))
            echo "ERROR: Failed to execute $project_name/build_stack_data.sh"
            echo ""
        fi
    fi
done

# Summary
echo "========================================"
echo "SUMMARY"
echo "========================================"
echo "Projects scanned: $(find "$SCRIPT_DIR" -maxdepth 1 -type d | wc -l)"
echo "Build scripts found: $total_found"
echo "Successfully executed: $total_executed"
echo "Errors: $total_errors"
echo ""

if [ -n "$DRY_RUN_FLAG" ]; then
    echo "This was a DRY RUN - no directories were created"
else
    echo "All directories have been created"
fi

exit 0
