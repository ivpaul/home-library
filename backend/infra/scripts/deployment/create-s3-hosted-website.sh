#!/bin/bash

# Create S3 bucket for hosting the frontend website
# This script creates a bucket, configures it for static website hosting,
# and sets up the necessary permissions

set -e

# Load configuration
if [ -f "config.json" ]; then
    BUCKET_NAME=$(jq -r '.s3.bucketName' config.json 2>/dev/null || echo "")
    REGION=$(jq -r '.aws.region' config.json 2>/dev/null || echo "us-east-1")
else
    echo "⚠️  config.json not found. Using default values."
    BUCKET_NAME=""
    REGION="us-east-1"
fi

# Prompt for bucket name if not in config
if [ -z "$BUCKET_NAME" ]; then
    echo "Enter S3 bucket name for hosting (must be globally unique):"
    read -r BUCKET_NAME
fi

echo "🚀 Creating S3 bucket for website hosting..."
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"

# Create S3 bucket
echo "📦 Creating S3 bucket..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null || \
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION"

# Configure bucket for static website hosting
echo "🌐 Configuring static website hosting..."
aws s3api put-bucket-website \
    --bucket "$BUCKET_NAME" \
    --website-configuration '{
        "IndexDocument": {"Suffix": "index.html"},
        "ErrorDocument": {"Key": "index.html"}
    }'

# Create bucket policy for public read access
echo "🔓 Setting up public read access..."
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file://bucket-policy.json

# Block public access settings (disable for website hosting)
echo "🔓 Configuring public access settings..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Update config.json with bucket information
if [ -f "config.json" ]; then
    echo "📝 Updating config.json..."
    # Create a temporary file with the new s3 section
    jq --arg bucket "$BUCKET_NAME" --arg region "$REGION" \
       '.s3 = {"bucketName": $bucket, "region": $region}' config.json > config.tmp.json
    mv config.tmp.json config.json
else
    echo "⚠️  config.json not found. Creating new one..."
    cat > config.json << EOF
{
  "aws": {
    "region": "$REGION",
    "environment": "prod"
  },
  "s3": {
    "bucketName": "$BUCKET_NAME",
    "region": "$REGION"
  }
}
EOF
fi

# Clean up temporary files
rm -f bucket-policy.json

# Get website URL
WEBSITE_URL=$(aws s3api get-bucket-website --bucket "$BUCKET_NAME" --query 'WebsiteEndpoint' --output text 2>/dev/null || echo "")

echo ""
echo "✅ S3 bucket setup complete!"
echo "📦 Bucket: $BUCKET_NAME"
echo "🌐 Website URL: http://$WEBSITE_URL"
echo ""
echo "📋 Next steps:"
echo "1. Add S3_BUCKET_NAME=$BUCKET_NAME to your GitHub Secrets"
echo "2. Deploy your frontend to test the setup"
echo "3. Consider setting up CloudFront for HTTPS and better performance"
echo ""
echo "🔧 To deploy manually:"
echo "  cd web && npm run build"
echo "  aws s3 sync build/ s3://$BUCKET_NAME --delete" 