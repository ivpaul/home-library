#!/bin/bash

# Home Library System - Rollback Script
# This script rolls back the deployment to a previous version

set -e

# Configuration
STACK_NAME="home-library-system"
REGION="us-east-1"
ENVIRONMENT=${ENVIRONMENT:-"prod"}

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

# Check if backup exists
check_backup() {
    log_info "Checking for backup..."
    
    if [ ! -d "../../backup" ]; then
        log_error "No backup directory found. Cannot rollback."
        exit 1
    fi
    
    log_success "Backup found"
}

# Rollback Lambda functions
rollback_lambda() {
    log_info "Rolling back Lambda functions..."
    
    cd ../../lambda
    
    # List of Lambda functions
    FUNCTIONS=("HomeLibraryGetBooks" "HomeLibraryCreateBook" "HomeLibraryUpdateBook" "HomeLibraryDeleteBook" "HomeLibraryGetBook")
    
    for function in "${FUNCTIONS[@]}"; do
        log_info "Rolling back $function..."
        
        # Check if backup exists
        if [ -f "../backup/${function}.zip" ]; then
            aws lambda update-function-code \
                --function-name "$function" \
                --zip-file "fileb://../backup/${function}.zip" \
                --no-cli-pager
            
            log_success "Rolled back $function"
        else
            log_warning "No backup found for $function, skipping..."
        fi
    done
    
    cd ../infra/scripts/ci-cd
}

# Rollback API Gateway (if needed)
rollback_api_gateway() {
    log_info "Checking API Gateway configuration..."
    
    # This would require more complex logic to rollback API Gateway changes
    # For now, we'll just log that it needs manual intervention
    log_warning "API Gateway rollback may require manual intervention"
    log_info "Check the API Gateway console for any configuration issues"
}

# Main rollback function
main() {
    log_warning "Starting rollback process..."
    log_info "This will revert Lambda functions to their previous versions"
    
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Rollback cancelled"
        exit 0
    fi
    
    check_backup
    rollback_lambda
    rollback_api_gateway
    
    log_success "🎉 Rollback completed!"
    log_info "Please test your application to ensure everything is working correctly"
}

main "$@" 