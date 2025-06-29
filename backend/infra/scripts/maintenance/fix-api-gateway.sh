#!/bin/bash

API_ID="k83276hq04"

echo "Fixing API Gateway configuration..."

# Get resource IDs
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/`].id' --output text)
BOOKS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`books`].id' --output text)
BOOK_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`{isbn}`].id' --output text)

echo "Resource IDs:"
echo "  Root: $ROOT_ID"
echo "  Books: $BOOKS_ID"
echo "  Book: $BOOK_ID"

# Enable CORS for /books resource
echo "Enabling CORS for /books resource..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --authorization-type NONE

aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true,
        "method.response.header.Access-Control-Allow-Origin": true
    }'

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}'

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''",
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }'

# Enable CORS for /books/{isbn} resource
echo "Enabling CORS for /books/{isbn} resource..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --authorization-type NONE

aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true,
        "method.response.header.Access-Control-Allow-Origin": true
    }'

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}'

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''",
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }'

# Redeploy the API
echo "Redeploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod

echo "✅ API Gateway configuration fixed!"
echo ""
echo "Test the API again:"
echo "  curl https://$API_ID.execute-api.us-east-1.amazonaws.com/prod/books" 