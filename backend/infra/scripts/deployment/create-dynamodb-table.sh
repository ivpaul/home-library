#!/bin/bash

# Home Library System - DynamoDB Table Creation Script
# This script creates the DynamoDB table with user-based partitioning

set -e

# Configuration
TABLE_NAME="HomeLibraryBooks"
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

# Check if table already exists
check_table_exists() {
    log_info "Checking if table already exists..."
    
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" &> /dev/null; then
        log_warning "Table $TABLE_NAME already exists"
        return 0
    else
        log_info "Table $TABLE_NAME does not exist, creating..."
        return 1
    fi
}

# Create DynamoDB table
create_table() {
    log_info "Creating DynamoDB table: $TABLE_NAME"
    
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions \
            AttributeName=userId,AttributeType=S \
            AttributeName=isbn,AttributeType=S \
        --key-schema \
            AttributeName=userId,KeyType=HASH \
            AttributeName=isbn,KeyType=RANGE \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --no-cli-pager
    
    log_success "Table creation initiated"
}

# Wait for table to be active
wait_for_table() {
    log_info "Waiting for table to become active..."
    
    aws dynamodb wait table-exists \
        --table-name "$TABLE_NAME" \
        --region "$REGION"
    
    log_success "Table is now active"
}

# Create GSI for searching by ISBN across users (for shared library features)
create_gsi() {
    log_info "Creating Global Secondary Index for ISBN search..."
    
    aws dynamodb update-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions \
            AttributeName=isbn,AttributeType=S \
            AttributeName=available,AttributeType=N \
        --global-secondary-indexes \
            IndexName=IsbnIndex,KeySchema=[{AttributeName=isbn,KeyType=HASH},{AttributeName=available,KeyType=RANGE}],Projection={ProjectionType=ALL} \
        --region "$REGION" \
        --no-cli-pager
    
    log_success "GSI creation initiated"
}

# Wait for GSI to be active
wait_for_gsi() {
    log_info "Waiting for GSI to become active..."
    
    aws dynamodb wait table-exists \
        --table-name "$TABLE_NAME" \
        --region "$REGION"
    
    # Additional wait for GSI
    sleep 30
    
    log_success "GSI is now active"
}

# Create sample data for testing
create_sample_data() {
    log_info "Creating sample data..."
    
    # Sample admin user ID (this will be replaced with actual Cognito user IDs)
    ADMIN_USER_ID="admin-user-123"
    
    # Sample books
    aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item '{
            "userId": {"S": "'$ADMIN_USER_ID'"},
            "isbn": {"S": "9780141439518"},
            "title": {"S": "Pride and Prejudice"},
            "author": {"S": "Jane Austen"},
            "year": {"N": "1813"},
            "pages": {"N": "432"},
            "available": {"N": "1"},
            "notes": {"S": "Classic romance novel"},
            "createdAt": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"},
            "updatedAt": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
        }' \
        --region "$REGION" \
        --no-cli-pager
    
    aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item '{
            "userId": {"S": "'$ADMIN_USER_ID'"},
            "isbn": {"S": "9780061120084"},
            "title": {"S": "To Kill a Mockingbird"},
            "author": {"S": "Harper Lee"},
            "year": {"N": "1960"},
            "pages": {"N": "376"},
            "available": {"N": "0"},
            "notes": {"S": "Currently checked out"},
            "createdAt": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"},
            "updatedAt": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
        }' \
        --region "$REGION" \
        --no-cli-pager
    
    log_success "Sample data created"
}

# Main function
main() {
    log_info "Setting up DynamoDB table for Home Library System..."
    
    if check_table_exists; then
        log_warning "Table already exists. Skipping creation."
        return 0
    fi
    
    create_table
    wait_for_table
    create_gsi
    wait_for_gsi
    create_sample_data
    
    log_success "🎉 DynamoDB table setup completed successfully!"
    log_info "Table name: $TABLE_NAME"
    log_info "Region: $REGION"
    log_info "Primary key: userId (HASH) + isbn (RANGE)"
    log_info "GSI: IsbnIndex (isbn + available)"
}

main "$@" 