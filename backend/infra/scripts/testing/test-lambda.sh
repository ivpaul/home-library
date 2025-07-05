#!/bin/bash

echo "Testing Lambda functions..."

# Test GetBooks function
echo "Testing GetBooks function..."
aws lambda invoke \
    --function-name HomeLibraryGetBooks \
    --payload '{}' \
    --cli-binary-format raw-in-base64-out \
    response.json

echo "GetBooks response:"
cat response.json
echo ""

# Test UpdateBook function with proper API Gateway event structure
echo "Testing UpdateBook function..."
aws lambda invoke \
    --function-name HomeLibraryUpdateBook \
    --payload file://update-book-payload.json \
    --cli-binary-format raw-in-base64-out \
    response2.json

echo "UpdateBook response:"
cat response2.json
echo ""

# Clean up
rm -f response.json response2.json

echo "✅ Lambda function tests completed!" 