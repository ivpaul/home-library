#!/bin/bash

API_ID="zit3ozv33d"

echo "🔧 Making GET endpoints public..."
echo "================================="

# Get resource IDs
echo "1. Getting resource IDs..."

# Get all resources
RESOURCES=$(aws apigateway get-resources --rest-api-id $API_ID --no-cli-pager)
echo "Resources found:"
echo "$RESOURCES" | jq '.items[] | {id: .id, path: .path, parentId: .parentId}'

# Find /books resource
BOOKS_RESOURCE_ID=$(echo "$RESOURCES" | jq -r '.items[] | select(.path == "/books") | .id')
echo "Books resource ID: $BOOKS_RESOURCE_ID"

# Find /books/{isbn} resource
BOOK_ISBN_RESOURCE_ID=$(echo "$RESOURCES" | jq -r '.items[] | select(.path == "/books/{isbn}") | .id')
echo "Book ISBN resource ID: $BOOK_ISBN_RESOURCE_ID"

if [ -z "$BOOKS_RESOURCE_ID" ]; then
    echo "❌ /books resource not found"
    exit 1
fi

if [ -z "$BOOK_ISBN_RESOURCE_ID" ]; then
    echo "❌ /books/{isbn} resource not found"
    exit 1
fi

echo "2. Making GET /books public..."
# Update GET method on /books to remove authorization
aws apigateway update-method \
  --rest-api-id $API_ID \
  --resource-id $BOOKS_RESOURCE_ID \
  --http-method GET \
  --patch-operations op=replace,path=/authorizationType,value=NONE \
  --no-cli-pager

echo "3. Making GET /books/{isbn} public..."
# Update GET method on /books/{isbn} to remove authorization
aws apigateway update-method \
  --rest-api-id $API_ID \
  --resource-id $BOOK_ISBN_RESOURCE_ID \
  --http-method GET \
  --patch-operations op=replace,path=/authorizationType,value=NONE \
  --no-cli-pager

echo "4. Creating new deployment..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --query 'id' \
  --output text)

echo "✅ GET endpoints are now public!"
echo "POST, PUT, DELETE endpoints remain authenticated."
echo "Deployment ID: $DEPLOYMENT_ID" 