#!/bin/bash

# Cleanup script for Cognito resources
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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Read current IDs
if [ -f ".user-pool-id" ]; then
    USER_POOL_ID=$(cat .user-pool-id)
    log_info "Found User Pool ID: $USER_POOL_ID"
else
    log_error "No User Pool ID file found"
    exit 1
fi

if [ -f ".identity-pool-id" ]; then
    IDENTITY_POOL_ID=$(cat .identity-pool-id)
    log_info "Found Identity Pool ID: $IDENTITY_POOL_ID"
else
    log_error "No Identity Pool ID file found"
    exit 1
fi

# Delete Identity Pool first (it depends on User Pool)
log_info "Deleting Identity Pool: $IDENTITY_POOL_ID"
aws cognito-identity delete-identity-pool --identity-pool-id "$IDENTITY_POOL_ID" --region us-east-1
log_success "Identity Pool deleted"

# Delete IAM roles
log_info "Deleting IAM roles..."
aws iam delete-role-policy --role-name "Cognito_HomeLibraryAuth_Role" --policy-name "CognitoHomeLibraryAuthPolicy" 2>/dev/null || log_warning "Auth role policy not found"
aws iam delete-role --role-name "Cognito_HomeLibraryAuth_Role" 2>/dev/null || log_warning "Auth role not found"

aws iam delete-role-policy --role-name "Cognito_HomeLibraryUnauth_Role" --policy-name "CognitoHomeLibraryUnauthPolicy" 2>/dev/null || log_warning "Unauth role policy not found"
aws iam delete-role --role-name "Cognito_HomeLibraryUnauth_Role" 2>/dev/null || log_warning "Unauth role not found"

log_success "IAM roles deleted"

# Delete User Pool (this will also delete the client)
log_info "Deleting User Pool: $USER_POOL_ID"
aws cognito-idp delete-user-pool --user-pool-id "$USER_POOL_ID" --region us-east-1
log_success "User Pool deleted"

# Remove ID files
rm -f .user-pool-id .client-id .identity-pool-id

log_success "Cleanup completed! Ready to create new Cognito resources." 