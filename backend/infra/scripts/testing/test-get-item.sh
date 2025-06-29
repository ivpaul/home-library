#!/bin/bash

echo "Testing get-item for The Hobbit..."

# Try to get a specific book
aws dynamodb get-item \
  --table-name HomeLibraryBooks \
  --key '{"isbn": {"S": "9780547928240"}}' \
  --region us-east-1

echo ""
echo "If you see JSON output above, the data was added successfully!" 