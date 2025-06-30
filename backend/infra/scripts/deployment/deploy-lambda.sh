#!/bin/bash

# Home Library System - Lambda Deployment Script
# This script deploys all Lambda functions

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

# Load configuration from config.json or environment variables
if [ -f "config.json" ]; then
    # Use config.json if available (local development)
    REGION=$(jq -r '.aws.region' config.json)
    log_info "Using config.json for configuration"
elif [ -n "$AWS_REGION" ]; then
    # Use environment variables (GitHub Actions)
    REGION="$AWS_REGION"
    log_info "Using environment variables for configuration"
else
    # Default fallback
    REGION="us-east-1"
    log_info "Using default region: $REGION"
fi

ROLE_NAME="HomeLibraryLambdaRole"

echo "Deploying Lambda functions..."
log_info "Using region: $REGION"

# Navigate to lambda directory
cd ../../../lambda

# Create IAM role for Lambda
log_info "Creating IAM role for Lambda..."

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || \
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }' \
        --query 'Role.Arn' \
        --output text \
        --no-cli-pager)

log_info "Using role ARN: $ROLE_ARN"

# Attach basic execution role
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
    --no-cli-pager

# Attach DynamoDB policy
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
    --no-cli-pager

# Wait for role to be available
log_info "Waiting for IAM role to be available..."
sleep 10

# Function configurations
FUNCTIONS=(
    "getBooks:HomeLibraryGetBooks"
    "getBook:HomeLibraryGetBook"
    "createBook:HomeLibraryCreateBook"
    "updateBook:HomeLibraryUpdateBook"
    "deleteBook:HomeLibraryDeleteBook"
)

# Deploy each function
for func_config in "${FUNCTIONS[@]}"; do
    IFS=':' read -r func_file func_name <<< "$func_config"
    
    log_info "Creating/updating $func_name Lambda function..."
    
    # Check if function exists
    if aws lambda get-function --function-name "$func_name" --region "$REGION" &> /dev/null; then
        log_info "Updating existing $func_name function..."
        
        # Update function code
        aws lambda update-function-code \
            --function-name "$func_name" \
            --zip-file "fileb://${func_file}.zip" \
            --region "$REGION" \
            --no-cli-pager
        
        # Update function configuration
        aws lambda update-function-configuration \
            --function-name "$func_name" \
            --runtime "nodejs20.x" \
            --handler "${func_file}.handler" \
            --role "$ROLE_ARN" \
            --timeout 30 \
            --memory-size 128 \
            --region "$REGION" \
            --no-cli-pager
            
    else
        log_info "Creating new $func_name function..."
        
        # Create function
        aws lambda create-function \
            --function-name "$func_name" \
            --runtime "nodejs20.x" \
            --handler "${func_file}.handler" \
            --role "$ROLE_ARN" \
            --zip-file "fileb://${func_file}.zip" \
            --timeout 30 \
            --memory-size 128 \
            --region "$REGION" \
            --no-cli-pager
    fi
    
    log_success "$func_name deployed successfully"
done

log_success "✅ Lambda functions deployed successfully!"

# Display function ARNs
echo ""
echo "Function ARNs:"
for func_config in "${FUNCTIONS[@]}"; do
    IFS=':' read -r func_file func_name <<< "$func_config"
    ARN=$(aws lambda get-function --function-name "$func_name" --region "$REGION" --query 'Configuration.FunctionArn' --output text --no-cli-pager)
    echo "  $func_name: $ARN"
done 