#!/bin/bash

echo "🔧 Fixing Cognito User Pool Client authentication flows..."
echo "=========================================================="

# Read the IDs from files
USER_POOL_ID=$(cat ../deployment/.user-pool-id)
CLIENT_ID=$(cat ../deployment/.client-id)

echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"

echo ""
echo "Current authentication flows:"
aws cognito-idp describe-user-pool-client \
  --user-pool-id "$USER_POOL_ID" \
  --client-id "$CLIENT_ID" \
  --query "UserPoolClient.ExplicitAuthFlows" \
  --output table \
  --no-cli-pager

echo ""
echo "Updating client to include USER_SRP_AUTH..."

aws cognito-idp update-user-pool-client \
  --user-pool-id "$USER_POOL_ID" \
  --client-id "$CLIENT_ID" \
  --explicit-auth-flows ALLOW_USER_SRP_AUTH ALLOW_REFRESH_TOKEN_AUTH ALLOW_USER_PASSWORD_AUTH \
  --no-cli-pager

if [ $? -eq 0 ]; then
    echo "✅ Successfully updated User Pool Client!"
    echo ""
    echo "New authentication flows:"
    aws cognito-idp describe-user-pool-client \
      --user-pool-id "$USER_POOL_ID" \
      --client-id "$CLIENT_ID" \
      --query "UserPoolClient.ExplicitAuthFlows" \
      --output table \
      --no-cli-pager
else
    echo "❌ Failed to update User Pool Client"
    echo "You may need to run this with elevated permissions or update via AWS Console"
    echo ""
    echo "Alternative: Update via AWS Console:"
    echo "1. Go to AWS Cognito Console"
    echo "2. Select your User Pool: $USER_POOL_ID"
    echo "3. Go to 'App integration' tab"
    echo "4. Find your app client: $CLIENT_ID"
    echo "5. Click 'Edit' and enable 'USER_SRP_AUTH'"
fi 