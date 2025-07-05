#!/bin/bash

# Home Library System - Main Deployment Script
# This script orchestrates the complete deployment of the backend infrastructure

set -e  # Exit on any error

# Configuration
STACK_NAME="home-library-system"
REGION="us-east-1"
ENVIRONMENT=${ENVIRONMENT:-"prod"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if jq is installed (needed for JSON parsing)
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Please install it first."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "../../../lambda/package.json" ]; then
        log_error "This script must be run from the infra/scripts/ci-cd directory"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Install dependencies
install_dependencies() {
    log_info "Installing Lambda dependencies..."
    cd ../../../lambda
    
    if [ ! -d "node_modules" ]; then
        npm install
        log_success "Dependencies installed"
    else
        log_info "Dependencies already installed, skipping..."
    fi
    
    cd ../infra/scripts/ci-cd
}

# Create deployment packages
create_deployment_packages() {
    log_info "Creating deployment packages..."
    cd ../../../lambda
    
    # Clean up old zip files
    rm -f *.zip
    
    # Create zip files for each Lambda function
    for function in getBooks getBook createBook updateBook deleteBook; do
        log_info "Creating package for $function..."
        zip -r "${function}.zip" "${function}.js" node_modules package.json
    done
    
    log_success "Deployment packages created"
    cd ../infra/scripts/ci-cd
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure..."
    
    # Deploy DynamoDB table
    log_info "Creating DynamoDB table..."
    ../deployment/create-dynamodb-table.sh
    
    # Deploy Lambda functions
    log_info "Deploying Lambda functions..."
    ../deployment/deploy-lambda.sh
    
    # Deploy API Gateway
    log_info "Creating API Gateway..."
    ../deployment/create-api-gateway.sh
    
    # Setup IAM permissions
    log_info "Setting up IAM permissions..."
    ../deployment/setup-iam-permissions.sh
    
    log_success "Infrastructure deployment completed"
}

# Setup Cognito (if not already set up)
setup_cognito() {
    log_info "Setting up Cognito authentication..."
    
    if [ ! -f "../deployment/cognito-config.json" ]; then
        log_info "Creating Cognito User Pool and Identity Pool..."
        cd ../deployment
        ./create-cognito.sh
        cd ../ci-cd
    else
        log_info "Cognito already configured, skipping creation..."
    fi
    
    # Setup API Gateway authorizer
    log_info "Setting up API Gateway authorizer..."
    cd ../deployment
    ./setup-cognito-authorizer.sh
    cd ../ci-cd
    
    log_success "Cognito setup completed"
}

# Run tests
run_tests() {
    log_info "Running tests..."
    
    # Test Lambda functions
    ../testing/test-lambda.sh
    
    # Test API endpoints (will require authentication)
    log_warning "API tests will require authentication tokens"
    log_info "Manual testing required with Cognito JWT tokens"
    
    log_success "Basic tests completed"
}

# Get API Gateway URL
get_api_url() {
    log_info "Getting API Gateway URL..."
    
    # Try to get the URL from the API Gateway configuration
    if [ -f "../deployment/.api-gateway-id" ]; then
        API_ID=$(cat ../deployment/.api-gateway-id)
        API_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
        echo "$API_URL"
    else
        log_warning "API Gateway ID not found. Please check the deployment."
        echo "UNKNOWN"
    fi
}

# Main deployment function
main() {
    log_info "Starting deployment for environment: $ENVIRONMENT"
    log_info "Region: $REGION"
    
    check_prerequisites
    install_dependencies
    create_deployment_packages
    deploy_infrastructure
    setup_cognito
    run_tests
    
    # Get the actual API Gateway URL
    API_URL=$(get_api_url)
    
    log_success "🎉 Deployment completed successfully!"
    log_info "Your API Gateway URL: $API_URL"
    log_warning "All endpoints now require authentication"
    log_info "Admin user: admin@homelibrary.com"
    log_info "Check Cognito User Pool for current password"
}

# Run main function
main "$@" 