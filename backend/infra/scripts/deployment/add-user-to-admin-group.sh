#!/bin/bash

# Home Library System - Add User to Admin Group
# This script adds a user to the admin group

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

# Check if required files exist
if [ ! -f ".user-pool-id" ]; then
    log_error "User Pool ID file not found. Please run create-cognito.sh first."
    exit 1
fi

USER_POOL_ID=$(cat .user-pool-id)
log_info "User Pool ID: $USER_POOL_ID"

# Get the username from command line argument
if [ -z "$1" ]; then
    log_error "Please provide the username as an argument."
    log_info "Usage: $0 <username>"
    log_info "Example: $0 8458e448-50b1-706a-88b3-69d38293f991"
    exit 1
fi

USERNAME="$1"
log_info "Adding user '$USERNAME' to admin group..."

# Add user to admin group
aws cognito-idp admin-add-user-to-group \
    --user-pool-id "$USER_POOL_ID" \
    --username "$USERNAME" \
    --group-name "admin" \
    --no-cli-pager

log_success "✅ User '$USERNAME' added to admin group successfully!"

# Verify the user is in the admin group
log_info "Verifying user group membership..."
aws cognito-idp admin-list-groups-for-user \
    --username "$USERNAME" \
    --user-pool-id "$USER_POOL_ID" \
    --no-cli-pager 