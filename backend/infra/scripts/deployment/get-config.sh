#!/bin/bash

# Helper script to read values from config.json
# Usage: ./get-config.sh <key>
# Example: ./get-config.sh aws.region
# Example: ./get-config.sh cognito.userPoolId

if [ $# -eq 0 ]; then
    echo "Usage: $0 <config_key>"
    echo "Example: $0 aws.region"
    echo "Example: $0 cognito.userPoolId"
    echo "Example: $0 apiGateway.url"
    exit 1
fi

CONFIG_KEY="$1"

if [ ! -f "config.json" ]; then
    echo "Error: config.json not found" >&2
    exit 1
fi

# Read the value from config.json
VALUE=$(jq -r ".$CONFIG_KEY" config.json 2>/dev/null)

if [ "$VALUE" = "null" ] || [ -z "$VALUE" ]; then
    echo "Error: Key '$CONFIG_KEY' not found in config.json" >&2
    exit 1
fi

echo "$VALUE" 