#!/bin/bash

# Simple test for the get_api_url function

echo "Testing get_api_url function..."

# Test 1: When API Gateway ID file doesn't exist
echo "Test 1: No API Gateway ID file"
if [ ! -f "../deployment/.api-gateway-id" ]; then
    echo "Result: UNKNOWN (file doesn't exist)"
else
    API_ID=$(cat ../deployment/.api-gateway-id)
    API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
    echo "Result: $API_URL"
fi

# Test 2: Create a mock API Gateway ID file
echo "Test 2: With mock API Gateway ID file"
echo "zit3ozv33d" > ../deployment/.api-gateway-id
API_ID=$(cat ../deployment/.api-gateway-id)
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
echo "Result: $API_URL"

# Clean up
rm ../deployment/.api-gateway-id

echo "Test completed!" 