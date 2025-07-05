#!/bin/bash

# Home Library System - Fix CORS Configuration
# This script adds CORS headers to API Gateway responses

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if API Gateway ID file exists
if [ ! -f ".api-gateway-id" ]; then
    log_error "API Gateway ID file not found. Please run create-api-gateway.sh first."
    exit 1
fi

API_ID=$(cat .api-gateway-id)
log_info "Fixing CORS for API Gateway: $API_ID"

# Get resource IDs
BOOKS_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/books`].id' \
    --output text \
    --no-cli-pager)

BOOK_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/books/{isbn}`].id' \
    --output text \
    --no-cli-pager)

log_info "Books Resource ID: $BOOKS_ID"
log_info "Book Resource ID: $BOOK_ID"

# Add OPTIONS method to /books resource for CORS preflight
log_info "Adding OPTIONS method to /books resource..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --no-cli-pager

# Add OPTIONS integration (mock response)
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
    --no-cli-pager

# Add OPTIONS method response
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true,
        "method.response.header.Access-Control-Allow-Origin": true
    }' \
    --no-cli-pager

# Add OPTIONS integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''",
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }' \
    --no-cli-pager

# Add OPTIONS method to /books/{isbn} resource
log_info "Adding OPTIONS method to /books/{isbn} resource..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --no-cli-pager

# Add OPTIONS integration (mock response)
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
    --no-cli-pager

# Add OPTIONS method response
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true,
        "method.response.header.Access-Control-Allow-Origin": true
    }' \
    --no-cli-pager

# Add OPTIONS integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''",
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }' \
    --no-cli-pager

# Update existing methods to include CORS headers in responses
log_info "Updating existing methods to include CORS headers..."

# Update GET /books method response
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method GET \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true
    }' \
    --no-cli-pager

# Update GET /books integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method GET \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }' \
    --no-cli-pager

# Update POST /books method response
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method POST \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true
    }' \
    --no-cli-pager

# Update POST /books integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method POST \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }' \
    --no-cli-pager

# Update PUT /books/{isbn} method response
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method PUT \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true
    }' \
    --no-cli-pager

# Update PUT /books/{isbn} integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method PUT \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }' \
    --no-cli-pager

# Update DELETE /books/{isbn} method response
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true
    }' \
    --no-cli-pager

# Update DELETE /books/{isbn} integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }' \
    --no-cli-pager

# Deploy the API
log_info "Deploying API with CORS configuration..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --no-cli-pager

log_success "✅ CORS configuration completed!"
log_info "Your frontend should now be able to access the API from localhost:3000" 