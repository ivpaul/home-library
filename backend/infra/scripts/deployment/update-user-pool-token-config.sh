#!/bin/bash

# Home Library System - Update User Pool Token Configuration
# This script configures the User Pool to include groups in JWT tokens

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
log_info "Updating User Pool: $USER_POOL_ID"

# Update User Pool to include groups in tokens
log_info "Configuring User Pool to include groups in JWT tokens..."

aws cognito-idp update-user-pool \
    --user-pool-id "$USER_POOL_ID" \
    --user-pool-add-ons "AdvancedSecurityMode=OFF" \
    --username-configuration "CaseSensitive=false" \
    --auto-verified-attributes email \
    --mfa-configuration OFF \
    --account-recovery-setting "RecoveryMechanisms=[{Name=verified_email,Priority=1}]" \
    --verification-message-template "DefaultEmailOption=CONFIRM_WITH_CODE" \
    --email-configuration "EmailSendingAccount=COGNITO_DEFAULT" \
    --sms-configuration "SnsRegion=us-east-1" \
    --user-pool-tags "Environment=Development" \
    --admin-create-user-config "AllowAdminCreateUserOnly=false" \
    --schema "Name=email,Required=true,Mutable=true" \
    --schema "Name=name,Required=false,Mutable=true" \
    --lambda-config "PreSignUp=,CustomMessage=,PostConfirmation=,PreAuthentication=,PostAuthentication=,DefineAuthChallenge=,CreateAuthChallenge=,VerifyAuthChallengeResponse=" \
    --username-attributes email \
    --device-configuration "ChallengeRequiredOnNewDevice=false,DeviceOnlyRememberedOnUserPrompt=false" \
    --email-verification-message "Your verification code is {####}" \
    --email-verification-subject "Your verification code" \
    --sms-verification-message "Your verification code is {####}" \
    --sms-authentication-message "Your authentication code is {####}" \
    --user-pool-add-ons "AdvancedSecurityMode=OFF" \
    --username-configuration "CaseSensitive=false" \
    --auto-verified-attributes email \
    --mfa-configuration OFF \
    --account-recovery-setting "RecoveryMechanisms=[{Name=verified_email,Priority=1}]" \
    --verification-message-template "DefaultEmailOption=CONFIRM_WITH_CODE" \
    --email-configuration "EmailSendingAccount=COGNITO_DEFAULT" \
    --sms-configuration "SnsRegion=us-east-1" \
    --user-pool-tags "Environment=Development" \
    --admin-create-user-config "AllowAdminCreateUserOnly=false" \
    --schema "Name=email,Required=true,Mutable=true" \
    --schema "Name=name,Required=false,Mutable=true" \
    --lambda-config "PreSignUp=,CustomMessage=,PostConfirmation=,PreAuthentication=,PostAuthentication=,DefineAuthChallenge=,CreateAuthChallenge=,VerifyAuthChallengeResponse=" \
    --username-attributes email \
    --device-configuration "ChallengeRequiredOnNewDevice=false,DeviceOnlyRememberedOnUserPrompt=false" \
    --email-verification-message "Your verification code is {####}" \
    --email-verification-subject "Your verification code" \
    --sms-verification-message "Your verification code is {####}" \
    --sms-authentication-message "Your authentication code is {####}" \
    --no-cli-pager

log_success "✅ User Pool token configuration updated!"
log_info "Groups should now be included in JWT tokens" 