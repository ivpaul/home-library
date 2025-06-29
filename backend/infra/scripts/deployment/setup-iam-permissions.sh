#!/bin/bash

echo "Setting up IAM permissions for Home Library System..."

# Create the comprehensive policy
echo "Creating IAM policy..."
aws iam create-policy \
  --policy-name HomeLibraryFullAccessPolicy \
  --policy-document file://home-library-iam-policy.json \
  --description "Comprehensive policy for Home Library System operations (Cognito, DynamoDB, Lambda, API Gateway, IAM)"

# Get the policy ARN
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`HomeLibraryFullAccessPolicy`].Arn' --output text)

echo "Policy ARN: $POLICY_ARN"

# Attach the policy to your user
echo "Attaching policy to user..."
aws iam attach-user-policy \
  --user-name ivan-home-library \
  --policy-arn $POLICY_ARN

echo "✅ IAM permissions set up successfully!"
echo "You now have full access to Cognito, DynamoDB, Lambda, API Gateway, and IAM operations."
echo "You can now run the Cognito setup script without permission issues." 