#!/bin/bash

# Test script for deploy.sh functionality

# Source the functions from deploy.sh
source ./deploy.sh

echo "Testing get_api_url function..."

# Test 1: When API Gateway ID file doesn't exist
echo "Test 1: No API Gateway ID file"
result=$(get_api_url)
echo "Result: $result"

# Test 2: Create a mock API Gateway ID file
echo "Test 2: With mock API Gateway ID file"
echo "zit3ozv33d" > ../deployment/.api-gateway-id
result=$(get_api_url)
echo "Result: $result"

# Clean up
rm ../deployment/.api-gateway-id

echo "Test completed!" 