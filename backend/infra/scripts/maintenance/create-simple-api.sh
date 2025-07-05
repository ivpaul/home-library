#!/bin/bash

echo "Creating simple API Gateway for Home Library..."

# Create API Gateway
echo "Creating REST API..."
API_ID=$(aws apigateway create-rest-api \
    --name "HomeLibraryAPI" \
    --description "API for Home Library Management" \
    --query 'id' --output text)

if [ -z "$API_ID" ]; then
    echo "Failed to create API Gateway"
    exit 1
fi

echo "API Gateway ID: $API_ID"

# Get the root resource ID
ROOT_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/`].id' --output text)

echo "Root Resource ID: $ROOT_ID"

# Create /books resource
echo "Creating /books resource..."
BOOKS_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_ID \
    --path-part "books" \
    --query 'id' --output text)

echo "Books Resource ID: $BOOKS_ID"

# Get Lambda function ARNs
GET_BOOKS_ARN=$(aws lambda get-function --function-name HomeLibraryGetBooks --query 'Configuration.FunctionArn' --output text)
CREATE_BOOK_ARN=$(aws lambda get-function --function-name HomeLibraryCreateBook --query 'Configuration.FunctionArn' --output text)

echo "Lambda ARNs:"
echo "  GetBooks: $GET_BOOKS_ARN"
echo "  CreateBook: $CREATE_BOOK_ARN"

# Create GET /books method
echo "Creating GET /books method..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method GET \
    --authorization-type NONE

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$(aws configure get region):lambda:path/2015-03-31/functions/$GET_BOOKS_ARN/invocations

# Create POST /books method
echo "Creating POST /books method..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method POST \
    --authorization-type NONE

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$(aws configure get region):lambda:path/2015-03-31/functions/$CREATE_BOOK_ARN/invocations

# Add Lambda permissions
echo "Adding Lambda permissions..."
aws lambda add-permission \
    --function-name HomeLibraryGetBooks \
    --statement-id apigateway-getbooks-$(date +%s) \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):$API_ID/*/GET/books"

aws lambda add-permission \
    --function-name HomeLibraryCreateBook \
    --statement-id apigateway-createbook-$(date +%s) \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):$API_ID/*/POST/books"

# Deploy the API
echo "Deploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod

echo "✅ Simple API Gateway created successfully!"
echo ""
echo "API Gateway ID: $API_ID"
echo "Base URL: https://$API_ID.execute-api.$(aws configure get region).amazonaws.com/prod"
echo ""
echo "Available endpoints:"
echo "  GET    /books                    - Get all books"
echo "  POST   /books                    - Create a new book"
echo ""
echo "Test with:"
echo "  curl https://$API_ID.execute-api.$(aws configure get region).amazonaws.com/prod/books" 