#!/bin/bash

API_ID="zit3ozv33d"
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get the /books/{isbn} resource ID
BOOK_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`{isbn}`].id' --output text)

echo "/books/{isbn} resource ID: $BOOK_ID"

# Get Lambda ARN
GET_BOOK_ARN=$(aws lambda get-function --function-name HomeLibraryGetBook --query 'Configuration.FunctionArn' --output text)

echo "GetBook Lambda ARN: $GET_BOOK_ARN"

# Add GET method to /books/{isbn}
echo "Adding GET /books/{isbn}..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method GET \
    --authorization-type NONE

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$GET_BOOK_ARN/invocations

# Add Lambda permission
aws lambda add-permission \
    --function-name HomeLibraryGetBook \
    --statement-id apigateway-getbook-$(date +%s) \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/books/*"

# Deploy the API
echo "Deploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod

echo "✅ GET /books/{isbn} endpoint added!"
echo "Test with:"
echo "  curl https://$API_ID.execute-api.$REGION.amazonaws.com/prod/books/9780743273565" 