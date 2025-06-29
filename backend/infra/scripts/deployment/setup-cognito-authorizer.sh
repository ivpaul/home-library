#!/bin/bash

# Home Library System - Setup Cognito Authorizer for API Gateway
# This script adds Cognito authorization to API Gateway endpoints

set -e

# Configuration
REGION="us-east-1"

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required files exist
if [ ! -f ".user-pool-id" ]; then
    log_error "User Pool ID file not found. Please run create-cognito.sh first."
    exit 1
fi

if [ ! -f ".api-gateway-id" ]; then
    log_error "API Gateway ID file not found. Please run create-api-gateway.sh first."
    exit 1
fi

# Read IDs from files
USER_POOL_ID=$(cat .user-pool-id)
API_ID=$(cat .api-gateway-id)

log_info "Setting up Cognito authorizer for API Gateway..."
log_info "User Pool ID: $USER_POOL_ID"
log_info "API Gateway ID: $API_ID"

# Get or create Cognito Authorizer
log_info "Checking for existing Cognito Authorizer..."

AUTHORIZER_ID=$(aws apigateway get-authorizers \
    --rest-api-id $API_ID \
    --query "items[?name=='CognitoAuthorizer'].id" \
    --output text \
    --no-cli-pager)

if [ -z "$AUTHORIZER_ID" ]; then
    log_info "No existing Cognito Authorizer found. Creating one..."
    AUTHORIZER_ID=$(aws apigateway create-authorizer \
        --rest-api-id $API_ID \
        --name "CognitoAuthorizer" \
        --type COGNITO_USER_POOLS \
        --provider-arns "arn:aws:cognito-idp:$REGION:$(aws sts get-caller-identity --query Account --output text):userpool/$USER_POOL_ID" \
        --identity-source "method.request.header.Authorization" \
        --query 'id' \
        --output text \
        --no-cli-pager)
    log_info "Created Cognito Authorizer with ID: $AUTHORIZER_ID"
else
    log_info "Found existing Cognito Authorizer with ID: $AUTHORIZER_ID"
fi

# Get resource IDs
log_info "Getting resource IDs..."

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

# If BOOK_ID is empty, try a different approach
if [ -z "$BOOK_ID" ]; then
    log_info "Trying alternative method to get book resource ID..."
    BOOK_ID=$(aws apigateway get-resources \
        --rest-api-id $API_ID \
        --query 'items[?contains(path,`{isbn}`)].id' \
        --output text \
        --no-cli-pager)
fi

log_info "Books Resource ID: $BOOKS_ID"
log_info "Book Resource ID: $BOOK_ID"

# Verify we have the resource IDs
if [ -z "$BOOKS_ID" ] || [ -z "$BOOK_ID" ]; then
    log_error "Failed to get resource IDs. Please check API Gateway configuration."
    exit 1
fi

# Update methods to require authorization
# Note: We'll keep GET /books public, but require auth for admin operations

log_info "Updating POST /books to require authorization..."
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $BOOKS_ID \
    --http-method POST \
    --patch-operations \
        op=replace,path=/authorizationType,value=COGNITO_USER_POOLS \
        op=replace,path=/authorizerId,value=$AUTHORIZER_ID \
    --no-cli-pager

log_info "Updating PUT /books/{isbn} to require authorization..."
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method PUT \
    --patch-operations \
        op=replace,path=/authorizationType,value=COGNITO_USER_POOLS \
        op=replace,path=/authorizerId,value=$AUTHORIZER_ID \
    --no-cli-pager

log_info "Updating DELETE /books/{isbn} to require authorization..."
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $BOOK_ID \
    --http-method DELETE \
    --patch-operations \
        op=replace,path=/authorizationType,value=COGNITO_USER_POOLS \
        op=replace,path=/authorizerId,value=$AUTHORIZER_ID \
    --no-cli-pager

# Deploy the updated API
log_info "Deploying updated API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --no-cli-pager

log_success "✅ Cognito authorizer setup completed!"
log_info ""
log_info "Protected endpoints (require admin login):"
log_info "  POST   /books                    - Create a new book"
log_info "  PUT    /books/{isbn}             - Update a book"
log_info "  DELETE /books/{isbn}             - Delete a book"
log_info ""
log_info "Public endpoints:"
log_info "  GET    /books                    - Get all books"
log_info ""
log_info "Users must be in the 'admin' group to access protected endpoints." 