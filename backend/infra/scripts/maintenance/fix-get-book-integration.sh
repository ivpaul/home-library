#!/bin/bash

API_ID="zit3ozv33d"
RESOURCE_ID="yi6ee7"

echo "🔧 Fixing GET /books/{isbn} integration..."
echo "=========================================="

# Update the integration to include request parameter mapping
aws apigateway update-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --patch-operations \
        op=replace,path=/requestParameters/method.request.path.isbn,value=integration.request.path.isbn

echo ""
echo "✅ Integration updated successfully!"

echo ""
echo "Creating new deployment..."
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod

echo ""
echo "✅ Deployment created! Testing the endpoint..."

sleep 5

echo ""
echo "Testing GET /books/{isbn}:"
curl -s https://$API_ID.execute-api.us-east-1.amazonaws.com/prod/books/9780061120084 | head -c 200
echo "" 