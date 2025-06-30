#!/bin/bash

# Home Library System - Backup Script
# This script creates backups of the current deployment

set -e

# Configuration
BACKUP_DIR="../../backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${TIMESTAMP}"

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

# Create backup directory
create_backup_dir() {
    log_info "Creating backup directory..."
    
    mkdir -p "$BACKUP_DIR"
    log_success "Backup directory created: $BACKUP_DIR"
}

# Backup Lambda functions
backup_lambda() {
    log_info "Creating Lambda function backups..."
    
    # Store the backup directory path
    BACKUP_PATH="$(pwd)/../../backup"
    
    cd ../../../lambda
    
    # List of Lambda functions
    FUNCTIONS=("HomeLibraryGetBooks" "HomeLibraryCreateBook" "HomeLibraryUpdateBook" "HomeLibraryDeleteBook" "HomeLibraryGetBook")
    
    for function in "${FUNCTIONS[@]}"; do
        log_info "Backing up $function..."
        
        # Download current version
        aws lambda get-function \
            --function-name "$function" \
            --query 'Code.Location' \
            --output text > /tmp/function_url.txt
        
        # Download the zip file
        curl -o "$BACKUP_PATH/${function}.zip" "$(cat /tmp/function_url.txt)"
        
        log_success "Backed up $function"
    done
    
    # Clean up
    rm -f /tmp/function_url.txt
    
    cd ../../infra/scripts/ci-cd
}

# Backup DynamoDB data
backup_dynamodb() {
    log_info "Creating DynamoDB backup..."
    
    # Create a backup of the table
    aws dynamodb create-backup \
        --table-name HomeLibraryBooks \
        --backup-name "HomeLibraryBooks_${TIMESTAMP}" \
        --no-cli-pager
    
    log_success "DynamoDB backup created"
}

# Create backup manifest
create_manifest() {
    log_info "Creating backup manifest..."
    
    cat > "$BACKUP_DIR/manifest.json" << EOF
{
  "backup_name": "$BACKUP_NAME",
  "timestamp": "$TIMESTAMP",
  "date": "$(date)",
  "components": {
    "lambda_functions": [
      "HomeLibraryGetBooks",
      "HomeLibraryCreateBook", 
      "HomeLibraryUpdateBook",
      "HomeLibraryDeleteBook",
      "HomeLibraryGetBook"
    ],
    "dynamodb_table": "HomeLibraryBooks"
  },
  "backup_files": [
    "HomeLibraryGetBooks.zip",
    "HomeLibraryCreateBook.zip",
    "HomeLibraryUpdateBook.zip", 
    "HomeLibraryDeleteBook.zip",
    "HomeLibraryGetBook.zip"
  ]
}
EOF
    
    log_success "Backup manifest created"
}

# Clean old backups
cleanup_old_backups() {
    log_info "Cleaning up old backups (keeping last 5)..."
    
    # Keep only the 5 most recent backups
    cd "$BACKUP_DIR"
    
    # Count total backups
    BACKUP_COUNT=$(ls -1 | grep -E "^backup_[0-9]{8}_[0-9]{6}$" | wc -l)
    
    if [ "$BACKUP_COUNT" -gt 5 ]; then
        # Remove oldest backups
        ls -1t | grep -E "^backup_[0-9]{8}_[0-9]{6}$" | tail -n +6 | xargs rm -rf
        log_success "Cleaned up old backups"
    else
        log_info "No cleanup needed (only $BACKUP_COUNT backups exist)"
    fi
    
    cd ../../infra/scripts/ci-cd
}

# Main backup function
main() {
    log_info "Starting backup process..."
    log_info "Backup name: $BACKUP_NAME"
    
    create_backup_dir
    backup_lambda
    backup_dynamodb
    create_manifest
    cleanup_old_backups
    
    log_success "🎉 Backup completed successfully!"
    log_info "Backup location: $BACKUP_DIR"
    log_info "Backup name: $BACKUP_NAME"
}

main "$@" 