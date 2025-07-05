#!/bin/bash

echo "Fixing Cognito User Pool Client authentication flows..."

USER_POOL_ID=$(cat .user-pool-id)
CLIENT_ID=$(cat .client-id)

echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"

# Update the user pool client to enable USER_SRP_AUTH
aws cognito-idp update-user-pool-client \
  --user-pool-id "$USER_POOL_ID" \
  --client-id "$CLIENT_ID" \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH ALLOW_USER_SRP_AUTH \
  --supported-identity-providers COGNITO

echo "✅ User Pool Client updated successfully!"
echo "ALLOW_USER_SRP_AUTH is now enabled." 