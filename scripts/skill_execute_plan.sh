#!/bin/bash

# Script to process workflow JSON files and execute defined steps.

set -e  # Exit on any error

# Function to process the workflow JSON file
process_workflow() {
    local json_file=$1
    # Iterate through each defined step in the JSON
    for step in $(jq -r '.steps[] | @base64' "$json_file"); do
        _jq() {
            echo ${step} | base64 --decode | jq -r ${1}
        }

        echo "Executing step: $(_jq '.name')"
        eval "$(_jq '.command')"
    done
}

# Main execution
if [[ -z "$1" ]]; then
    echo "No JSON file given. Usage: $0 <workflow-file.json>"
    exit 1
fi

process_workflow "$1"
