#!/bin/bash

# Load configuration from config.json
if [ ! -f "config.json" ]; then
    echo "Error: config.json not found. Please run setup scripts first."
    exit 1
fi

# Parse configuration
REGION=$(jq -r '.aws.region' config.json)

echo "Creating API Gateway for Home Library..."
echo "Using region: $REGION"

# Create API Gateway
echo "Creating REST API..."
API_ID=$(aws apigateway create-rest-api \
    --name "HomeLibraryAPI" \
    --description "API for Home Library Management" \
    --query 'id' --output text)

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

# Create /books/{isbn} resource
echo "Creating /books/{isbn} resource..."
BOOK_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $BOOKS_ID \
    --path-part "{isbn}" \
    --query 'id' --output text)

echo "Book Resource ID: $BOOK_ID"

# Get Lambda function ARNs
GET_BOOKS_ARN=$(aws lambda get-function --function-name HomeLibraryGetBooks --query 'Configuration.FunctionArn' --output text)
CREATE_BOOK_ARN=$(aws lambda get-function --function-name HomeLibraryCreateBook --query 'Configuration.FunctionArn' --output text)
UPDATE_BOOK_ARN=$(aws lambda get-function --function-name HomeLibraryUpdateBook --query 'Configuration.FunctionArn' --output text)
DELETE_BOOK_ARN=$(aws lambda get-function --function-name HomeLibraryDeleteBook --query 'Configuration.FunctionArn' --output text)

echo "Lambda ARNs:"
echo "  GetBooks: $GET_BOOKS_ARN"
echo "  CreateBook: $CREATE_BOOK_ARN"
echo "  UpdateBook: $UPDATE_BOOK_ARN"
echo "  DeleteBook: $DELETE_BOOK_ARN"

# Add Lambda permissions for API Gateway
echo "Adding Lambda permissions..."

aws lambda add-permission \
    --function-name HomeLibraryGetBooks \
    --statement-id apigateway-getbooks \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/GET/books"

aws lambda add-permission \
    --function-name HomeLibraryCreateBook \
    --statement-id apigateway-createbook \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/POST/books"

aws lambda add-permission \
    --function-name HomeLibraryUpdateBook \
    --statement-id apigateway-updatebook \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/PUT/books/*"

aws lambda add-permission \
    --function-name HomeLibraryDeleteBook \
    --statement-id apigateway-deletebook \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/DELETE/books/*"

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
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$GET_BOOKS_ARN/invocations

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
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$CREATE_BOOK_ARN/invocations

# Create PUT /books/{isbn} method
echo "Creating PUT /books/{isbn} method..."
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

# Create DELETE /books/{isbn} method
echo "Creating DELETE /books/{isbn} method..."
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

# Deploy the API
echo "Deploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod

echo "✅ API Gateway created successfully!"
echo ""
echo "API Gateway ID: $API_ID"
echo "Base URL: https://$API_ID.execute-api.$REGION.amazonaws.com/prod"

# Update config.json with the new API Gateway ID
echo "Updating config.json with API Gateway ID..."
jq --arg api_id "$API_ID" --arg region "$REGION" \
   '.apiGateway.id = $api_id | .apiGateway.url = "https://\($api_id).execute-api.\($region).amazonaws.com/prod"' \
   config.json > config.json.tmp && mv config.json.tmp config.json

echo "Config updated with API Gateway ID: $API_ID"

echo ""
echo "Available endpoints:"
echo "  GET    /books                    - Get all books"
echo "  POST   /books                    - Create a new book"
echo "  PUT    /books/{isbn}             - Update a book"
echo "  DELETE /books/{isbn}             - Delete a book"
echo ""
echo "Example usage:"
echo "  curl https://$API_ID.execute-api.$REGION.amazonaws.com/prod/books"
echo "  curl -X POST https://$API_ID.execute-api.$REGION.amazonaws.com/prod/books \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"isbn\":\"9780547928240\",\"title\":\"The Hobbit\",\"authorFirstName\":\"J.R.R.\",\"authorLastName\":\"Tolkien\"}'" 