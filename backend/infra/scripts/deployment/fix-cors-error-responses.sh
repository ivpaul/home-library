#!/bin/bash

# Home Library System - Fix CORS for Error Responses
# This script adds CORS headers to error responses in API Gateway

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
log_info "Fixing CORS for error responses in API Gateway: $API_ID"

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

# Add CORS headers to error responses for DELETE method
log_info "Adding CORS headers to error responses for DELETE method..."

# Add 401 response for DELETE
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 401 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true,
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true
    }' \
    --no-cli-pager

# Add 403 response for DELETE
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 403 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true,
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true
    }' \
    --no-cli-pager

# Add 500 response for DELETE
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 500 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true,
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true
    }' \
    --no-cli-pager

# Add integration responses for error codes
log_info "Adding integration responses for error codes..."

# 401 integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 401 \
    --selection-pattern ".*[UNAUTHORIZED].*" \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''",
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''"
    }' \
    --no-cli-pager

# 403 integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 403 \
    --selection-pattern ".*[FORBIDDEN].*" \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''",
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''"
    }' \
    --no-cli-pager

# 500 integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --status-code 500 \
    --selection-pattern ".*" \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''",
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''"
    }' \
    --no-cli-pager

# Deploy the API
log_info "Deploying API with CORS error response configuration..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --no-cli-pager

log_success "✅ CORS error response configuration completed!"
log_info "Error responses (401, 403, 500) now include CORS headers" 