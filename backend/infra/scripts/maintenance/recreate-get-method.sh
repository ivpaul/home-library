#!/bin/bash

API_ID="zit3ozv33d"
RESOURCE_ID="yi6ee7"

echo "🔄 Recreating GET /books/{isbn} method with AWS_PROXY integration..."
echo "===================================================================="

# Delete the existing GET method
echo "Deleting existing GET method..."
aws apigateway delete-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method GET

# Create the GET method
echo "Creating new GET method..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --authorization-type NONE \
    --request-parameters method.request.path.isbn=true

# Create the method response
echo "Creating method response..."
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --status-code 200 \
    --response-models application/json=Empty

# Create the integration
echo "Creating AWS_PROXY integration..."
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:985539761940:function:HomeLibraryGetBook/invocations

echo ""
echo "✅ Method recreated successfully!"

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