#!/bin/bash

API_ID="zit3ozv33d"
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get /books resource ID
BOOKS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/books`].id' --output text)

# Create /books/{isbn} resource
BOOK_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $BOOKS_ID \
    --path-part "{isbn}" \
    --query 'id' --output text)

echo "/books/{isbn} resource ID: $BOOK_ID"

# Get Lambda ARNs
UPDATE_BOOK_ARN=$(aws lambda get-function --function-name HomeLibraryUpdateBook --query 'Configuration.FunctionArn' --output text)
DELETE_BOOK_ARN=$(aws lambda get-function --function-name HomeLibraryDeleteBook --query 'Configuration.FunctionArn' --output text)

# PUT /books/{isbn}
echo "Adding PUT /books/{isbn}..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method PUT \
    --authorization-type NONE

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method PUT \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$UPDATE_BOOK_ARN/invocations

aws lambda add-permission \
    --function-name HomeLibraryUpdateBook \
    --statement-id apigateway-updatebook-$(date +%s) \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/PUT/books/*"

# DELETE /books/{isbn}
echo "Adding DELETE /books/{isbn}..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --authorization-type NONE

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$DELETE_BOOK_ARN/invocations

aws lambda add-permission \
    --function-name HomeLibraryDeleteBook \
    --statement-id apigateway-deletebook-$(date +%s) \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/DELETE/books/*"

# Deploy the API
echo "Deploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod

echo "✅ PUT and DELETE endpoints added!"
echo "Test with:"
echo "  curl -X PUT https://$API_ID.execute-api.$REGION.amazonaws.com/prod/books/9780547928240 -H 'Content-Type: application/json' -d '{\"status\":\"borrowed\",\"notes\":\"Checked out\"}'"
echo "  curl -X DELETE https://$API_ID.execute-api.$REGION.amazonaws.com/prod/books/9780547928240 -H 'Content-Type: application/json' -d '{\"isbn\":\"9780547928240\"}'" 