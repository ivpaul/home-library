#!/bin/bash

# Home Library System - Cognito Setup Script
# This script creates Cognito User Pool and Identity Pool with user roles

set -e

# Configuration
USER_POOL_NAME="HomeLibraryUsers"
IDENTITY_POOL_NAME="HomeLibraryIdentity"
REGION="us-east-1"
CLIENT_NAME="HomeLibraryClient"

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

# Check if User Pool already exists
check_user_pool_exists() {
    log_info "Checking if User Pool already exists..."
    
    # Try to list user pools and find ours
    EXISTING_POOL_ID=$(aws cognito-idp list-user-pools --max-results 20 --query "UserPools[?Name=='$USER_POOL_NAME'].Id" --output text --no-cli-pager 2>/dev/null || echo "")
    
    if [ ! -z "$EXISTING_POOL_ID" ]; then
        log_warning "User Pool '$USER_POOL_NAME' already exists: $EXISTING_POOL_ID"
        echo "$EXISTING_POOL_ID" > .user-pool-id
        return 0
    else
        log_info "User Pool does not exist, will create new one"
        return 1
    fi
}

# Check if Identity Pool already exists
check_identity_pool_exists() {
    log_info "Checking if Identity Pool already exists..."
    
    # Try to list identity pools and find ours
    EXISTING_IDENTITY_POOL_ID=$(aws cognito-identity list-identity-pools --max-results 20 --query "IdentityPools[?IdentityPoolName=='$IDENTITY_POOL_NAME'].IdentityPoolId" --output text --no-cli-pager 2>/dev/null || echo "")
    
    if [ ! -z "$EXISTING_IDENTITY_POOL_ID" ]; then
        log_warning "Identity Pool '$IDENTITY_POOL_NAME' already exists: $EXISTING_IDENTITY_POOL_ID"
        echo "$EXISTING_IDENTITY_POOL_ID" > .identity-pool-id
        return 0
    else
        log_info "Identity Pool does not exist, will create new one"
        return 1
    fi
}

# Check if IAM roles already exist
check_iam_roles_exist() {
    log_info "Checking if IAM roles already exist..."
    
    if aws iam get-role --role-name "Cognito_HomeLibraryAuth_Role" &>/dev/null && \
       aws iam get-role --role-name "Cognito_HomeLibraryUnauth_Role" &>/dev/null; then
        log_warning "IAM roles already exist, skipping creation"
        return 0
    else
        log_info "IAM roles do not exist, will create new ones"
        return 1
    fi
}

# Create Cognito User Pool
create_user_pool() {
    if check_user_pool_exists; then
        return 0
    fi
    
    log_info "Creating Cognito User Pool..."
    
    # Create the user pool
    USER_POOL_ID=$(aws cognito-idp create-user-pool \
        --pool-name "$USER_POOL_NAME" \
        --policies '{
            "PasswordPolicy": {
                "MinimumLength": 8,
                "RequireUppercase": true,
                "RequireLowercase": true,
                "RequireNumbers": true,
                "RequireSymbols": false
            }
        }' \
        --auto-verified-attributes email \
        --username-attributes email \
        --schema '[
            {
                "Name": "email",
                "AttributeDataType": "String",
                "Required": true,
                "Mutable": true
            },
            {
                "Name": "name",
                "AttributeDataType": "String",
                "Required": false,
                "Mutable": true
            },
            {
                "Name": "family_name",
                "AttributeDataType": "String",
                "Required": false,
                "Mutable": true
            }
        ]' \
        --query 'UserPool.Id' \
        --output text \
        --no-cli-pager)
    
    log_success "User Pool created: $USER_POOL_ID"
    echo "$USER_POOL_ID" > .user-pool-id

    # Skip adding custom:role attribute since it was added manually in Console
    log_info "Skipping custom:role attribute addition (already added manually)"
}

# Create User Pool Client
create_user_pool_client() {
    log_info "Creating User Pool Client..."
    
    USER_POOL_ID=$(cat .user-pool-id)
    
    # Check if client already exists
    EXISTING_CLIENT_ID=$(aws cognito-idp list-user-pool-clients --user-pool-id "$USER_POOL_ID" --query "UserPoolClients[?ClientName=='$CLIENT_NAME'].ClientId" --output text --no-cli-pager 2>/dev/null || echo "")
    
    if [ ! -z "$EXISTING_CLIENT_ID" ]; then
        log_warning "User Pool Client '$CLIENT_NAME' already exists: $EXISTING_CLIENT_ID"
        echo "$EXISTING_CLIENT_ID" > .client-id
        return 0
    fi
    
    CLIENT_ID=$(aws cognito-idp create-user-pool-client \
        --user-pool-id "$USER_POOL_ID" \
        --client-name "$CLIENT_NAME" \
        --no-generate-secret \
        --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
        --supported-identity-providers COGNITO \
        --query 'UserPoolClient.ClientId' \
        --output text \
        --no-cli-pager)
    
    log_success "User Pool Client created: $CLIENT_ID"
    echo "$CLIENT_ID" > .client-id
}

# Create Identity Pool
create_identity_pool() {
    if check_identity_pool_exists; then
        return 0
    fi
    
    log_info "Creating Identity Pool..."
    
    USER_POOL_ID=$(cat .user-pool-id)
    CLIENT_ID=$(cat .client-id)
    
    IDENTITY_POOL_ID=$(aws cognito-identity create-identity-pool \
        --identity-pool-name "$IDENTITY_POOL_NAME" \
        --allow-unauthenticated-identities \
        --cognito-identity-providers ProviderName="cognito-idp.$REGION.amazonaws.com/$USER_POOL_ID",ClientId="$CLIENT_ID",ServerSideTokenCheck=false \
        --query 'IdentityPoolId' \
        --output text \
        --no-cli-pager)
    
    log_success "Identity Pool created: $IDENTITY_POOL_ID"
    echo "$IDENTITY_POOL_ID" > .identity-pool-id
}

# Create IAM roles for authenticated and unauthenticated users
create_iam_roles() {
    if check_iam_roles_exist; then
        return 0
    fi
    
    log_info "Creating IAM roles..."
    
    IDENTITY_POOL_ID=$(cat .identity-pool-id)
    USER_POOL_ID=$(cat .user-pool-id)
    
    # Create authenticated role
    cat > authenticated-role-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "arn:aws:dynamodb:$REGION:*:table/HomeLibraryBooks"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "dynamodb:LeadingKeys": ["\${cognito-identity.amazonaws.com:sub}"]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "arn:aws:lambda:$REGION:*:function:HomeLibrary*"
            ]
        }
    ]
}
EOF
    
    # Create unauthenticated role (minimal permissions)
    cat > unauthenticated-role-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
    
    # Create the roles
    AUTHENTICATED_ROLE_ARN=$(aws iam create-role \
        --role-name "Cognito_HomeLibraryAuth_Role" \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": "cognito-identity.amazonaws.com"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "cognito-identity.amazonaws.com:aud": "'$IDENTITY_POOL_ID'"
                        },
                        "ForAnyValue:StringLike": {
                            "cognito-identity.amazonaws.com:amr": "authenticated"
                        }
                    }
                }
            ]
        }' \
        --query 'Role.Arn' \
        --output text \
        --no-cli-pager)
    
    UNAUTHENTICATED_ROLE_ARN=$(aws iam create-role \
        --role-name "Cognito_HomeLibraryUnauth_Role" \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": "cognito-identity.amazonaws.com"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "cognito-identity.amazonaws.com:aud": "'$IDENTITY_POOL_ID'"
                        },
                        "ForAnyValue:StringLike": {
                            "cognito-identity.amazonaws.com:amr": "unauthenticated"
                        }
                    }
                }
            ]
        }' \
        --query 'Role.Arn' \
        --output text \
        --no-cli-pager)
    
    # Attach policies to roles
    aws iam put-role-policy \
        --role-name "Cognito_HomeLibraryAuth_Role" \
        --policy-name "HomeLibraryAuthPolicy" \
        --policy-document file://authenticated-role-policy.json \
        --no-cli-pager
    
    aws iam put-role-policy \
        --role-name "Cognito_HomeLibraryUnauth_Role" \
        --policy-name "HomeLibraryUnauthPolicy" \
        --policy-document file://unauthenticated-role-policy.json \
        --no-cli-pager
    
    # Update identity pool with role ARNs
    aws cognito-identity set-identity-pool-roles \
        --identity-pool-id "$IDENTITY_POOL_ID" \
        --roles authenticated="$AUTHENTICATED_ROLE_ARN",unauthenticated="$UNAUTHENTICATED_ROLE_ARN" \
        --no-cli-pager
    
    log_success "IAM roles created and configured"
    
    # Clean up temporary files
    rm -f authenticated-role-policy.json unauthenticated-role-policy.json
}

# Create admin user
create_admin_user() {
    log_info "Creating admin user..."
    USER_POOL_ID=$(cat .user-pool-id)
    
    # Create admin user (no custom:role)
    aws cognito-idp admin-create-user \
        --user-pool-id "$USER_POOL_ID" \
        --username "admin@homelibrary.com" \
        --user-attributes Name=email,Value=admin@homelibrary.com Name=name,Value=Admin Name=email_verified,Value=true \
        --temporary-password "Admin123!" \
        --message-action SUPPRESS \
        --no-cli-pager
    
    log_success "Admin user created: admin@homelibrary.com"
    log_warning "Temporary password: Admin123!"
    log_info "User will be prompted to change password on first login"
}

# Create user group for admin role only
create_user_groups() {
    log_info "Creating admin group..."
    USER_POOL_ID=$(cat .user-pool-id)

    # Try to create admin group, skip if it already exists
    if aws cognito-idp create-group \
        --user-pool-id "$USER_POOL_ID" \
        --group-name "admin" \
        --description "Administrators with full access" \
        --precedence 1 \
        --no-cli-pager 2>&1 | grep -q 'GroupExistsException'; then
        log_warning "Admin group already exists, skipping creation."
    else
        log_success "Admin group created."
    fi
}

# Add admin user to admin group
add_admin_to_group() {
    log_info "Adding admin user to admin group..."
    USER_POOL_ID=$(cat .user-pool-id)
    aws cognito-idp admin-add-user-to-group \
        --user-pool-id "$USER_POOL_ID" \
        --username "admin@homelibrary.com" \
        --group-name "admin" \
        --no-cli-pager
    log_success "Admin user added to admin group"
}

# Save configuration
save_configuration() {
    log_info "Saving configuration..."
    
    USER_POOL_ID=$(cat .user-pool-id)
    CLIENT_ID=$(cat .client-id)
    IDENTITY_POOL_ID=$(cat .identity-pool-id)
    
    cat > cognito-config.json << EOF
{
    "userPoolId": "$USER_POOL_ID",
    "clientId": "$CLIENT_ID",
    "identityPoolId": "$IDENTITY_POOL_ID",
    "region": "$REGION",
    "userPoolName": "$USER_POOL_NAME",
    "identityPoolName": "$IDENTITY_POOL_NAME"
}
EOF
    
    log_success "Configuration saved to cognito-config.json"
}

# Clean up extra User Pools (use with caution!)
cleanup_extra_pools() {
    log_warning "This will list all User Pools and allow you to delete extra ones."
    log_warning "Only run this if you have multiple User Pools and want to clean up."
    
    echo ""
    log_info "Listing all User Pools:"
    aws cognito-idp list-user-pools --max-results 20 --query "UserPools[].{Name:Name,Id:Id,CreationDate:CreationDate}" --output table --no-cli-pager
    
    echo ""
    read -p "Do you want to delete any User Pools? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter the User Pool ID to delete (or 'cancel' to abort): " POOL_ID_TO_DELETE
        
        if [ "$POOL_ID_TO_DELETE" != "cancel" ]; then
            log_warning "Deleting User Pool: $POOL_ID_TO_DELETE"
            aws cognito-idp delete-user-pool --user-pool-id "$POOL_ID_TO_DELETE" --no-cli-pager
            log_success "User Pool deleted"
        else
            log_info "Deletion cancelled"
        fi
    fi
}

# Main execution
main() {
    log_info "Setting up Amazon Cognito for Home Library System"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Create resources
    create_user_pool
    create_user_pool_client
    create_identity_pool
    create_iam_roles
    create_user_groups
    create_admin_user
    add_admin_to_group
    
    log_success "Cognito setup completed successfully!"
    log_info "User Pool ID: $(cat .user-pool-id)"
    log_info "Client ID: $(cat .client-id)"
    log_info "Identity Pool ID: $(cat .identity-pool-id)"
    
    echo ""
    log_info "Next steps:"
    log_info "1. Update your frontend with the Cognito configuration"
    log_info "2. Test authentication flow"
}

# Check if cleanup is requested
if [ "$1" = "cleanup" ]; then
    cleanup_extra_pools
    exit 0
fi

# Run main function
main 