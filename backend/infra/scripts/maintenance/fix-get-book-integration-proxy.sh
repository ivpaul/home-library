#!/bin/bash

API_ID="zit3ozv33d"
RESOURCE_ID="yi6ee7"

echo "🔧 Fixing GET /books/{isbn} integration to use AWS_PROXY..."
echo "============================================================"

# Update the integration to use AWS_PROXY type
aws apigateway update-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --patch-operations \
        op=replace,path=/type,value=AWS_PROXY

echo ""
echo "✅ Integration updated to AWS_PROXY!"

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