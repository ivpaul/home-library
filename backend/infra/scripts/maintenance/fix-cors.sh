#!/bin/bash

API_ID="zit3ozv33d"

echo "🔧 Fixing CORS configuration..."
echo "================================"

# Add CORS headers to all Lambda functions
echo "1. Adding CORS headers to Lambda functions..."

# Update getBooks Lambda
echo "Updating getBooks Lambda..."
aws lambda update-function-code \
  --function-name HomeLibraryGetBooks \
  --zip-file fileb://../lambda/getBooks.zip \
  --no-cli-pager

# Update createBook Lambda  
echo "Updating createBook Lambda..."
aws lambda update-function-code \
  --function-name HomeLibraryCreateBook \
  --zip-file fileb://../lambda/createBook.zip \
  --no-cli-pager

# Update updateBook Lambda
echo "Updating updateBook Lambda..."
aws lambda update-function-code \
  --function-name HomeLibraryUpdateBook \
  --zip-file fileb://../lambda/updateBook.zip \
  --no-cli-pager

# Update deleteBook Lambda
echo "Updating deleteBook Lambda..."
aws lambda update-function-code \
  --function-name HomeLibraryDeleteBook \
  --zip-file fileb://../lambda/deleteBook.zip \
  --no-cli-pager

# Update getBook Lambda
echo "Updating getBook Lambda..."
aws lambda update-function-code \
  --function-name HomeLibraryGetBook \
  --zip-file fileb://../lambda/getBook.zip \
  --no-cli-pager

# Get resource IDs
echo "2. Adding OPTIONS method to /books resource for CORS preflight..."
BOOKS_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/books`].id' --output text | head -1)

# Add OPTIONS method to /books
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $BOOKS_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --no-cli-pager

# Add mock integration for OPTIONS
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $BOOKS_RESOURCE_ID \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
  --no-cli-pager

# Add method response for OPTIONS
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $BOOKS_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Headers":true,"method.response.header.Access-Control-Allow-Methods":true,"method.response.header.Access-Control-Allow-Origin":true}' \
  --no-cli-pager

# Add integration response for OPTIONS
aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $BOOKS_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' \
  --no-cli-pager

echo "3. Adding OPTIONS method to /books/{isbn} resource..."
BOOK_ISBN_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/books/{isbn}`].id' --output text | head -1)

# Add OPTIONS method to /books/{isbn}
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $BOOK_ISBN_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --no-cli-pager

# Add mock integration for OPTIONS
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $BOOK_ISBN_RESOURCE_ID \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
  --no-cli-pager

# Add method response for OPTIONS
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $BOOK_ISBN_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Headers":true,"method.response.header.Access-Control-Allow-Methods":true,"method.response.header.Access-Control-Allow-Origin":true}' \
  --no-cli-pager

# Add integration response for OPTIONS
aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $BOOK_ISBN_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' \
  --no-cli-pager

echo "4. Creating new deployment..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --query 'id' \
  --output text)

echo "✅ CORS configuration complete!"
echo "Your frontend should now be able to communicate with the API." 