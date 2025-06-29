# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated testing and deployment of the Home Library System.

## 📋 Workflow Overview

### 1. **Backend Workflow** (`deploy.yml`)
- **Triggers**: Changes to `backend/**` files
- **Purpose**: Deploy AWS serverless backend
- **Actions**:
  - Test Lambda functions
  - Deploy to AWS (Lambda, API Gateway, DynamoDB)
  - Run post-deployment tests

### 2. **Frontend Workflow** (`frontend.yml`)
- **Triggers**: Changes to `web/**` files
- **Purpose**: Deploy React frontend to S3
- **Actions**:
  - Test React application
  - Build production bundle
  - Deploy to S3 bucket
  - Invalidate CloudFront cache (optional)

## 🚀 S3 Hosting Setup

### Prerequisites
1. **Create S3 bucket for hosting**:
   ```bash
   cd backend/infra/scripts/deployment
   ./create-s3-hosted-website.sh
   ```

2. **Add required secrets to GitHub**:
   - `S3_BUCKET_NAME`: Your S3 bucket name
   - `CLOUDFRONT_DISTRIBUTION_ID`: (Optional) For CDN and HTTPS

### S3 Bucket Features
- ✅ **Static website hosting** configured
- ✅ **Public read access** for website files
- ✅ **SPA routing** (index.html for all routes)
- ✅ **Automatic deployment** via GitHub Actions

## 🔧 Configuration

### Required Secrets

#### AWS Authentication (OIDC)
- `AWS_ROLE_ARN`: ARN of the IAM role for GitHub Actions (created by setup-oidc.sh)

#### Backend Configuration
- `COGNITO_USER_POOL_ID` - Your Cognito User Pool ID (e.g., `us-east-1_XOAlNThzg`)
- `COGNITO_CLIENT_ID` - Your Cognito Client ID (e.g., `6o1g4cjic5sjbug0g71scu2vb`)
- `COGNITO_IDENTITY_POOL_ID` - Your Cognito Identity Pool ID (e.g., `us-east-1:505f2fef-cf0f-4fcc-a42b-9bb525390978`)
- `API_GATEWAY_ID` - Your API Gateway ID (e.g., `uy5tp26jg7`)
- `API_GATEWAY_URL` - Your API Gateway URL (e.g., `https://uy5tp26jg7.execute-api.us-east-1.amazonaws.com/prod`)
- `DYNAMODB_TABLE_NAME` - Your DynamoDB table name (e.g., `HomeLibraryBooks`)

#### Frontend Configuration
- `S3_BUCKET_NAME`: Your S3 bucket name (`ivpaul-home-library-app`)
- `CLOUDFRONT_DISTRIBUTION_ID`: (Optional) For CDN

## 🔐 OIDC Setup

### 1. Run the OIDC setup script:
```bash
cd backend/infra/scripts/deployment
./setup-oidc.sh
```

### 2. Add the role ARN to GitHub Secrets:
- Name: `AWS_ROLE_ARN`
- Value: The ARN output by the setup script

### 3. Remove old credentials:
- Delete `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets

## 🔄 Workflow Behavior

### Independent Deployments
- **Backend changes** only trigger backend deployment
- **Frontend changes** only trigger frontend deployment
- **Both can run simultaneously** if both directories change

### Testing
- **Pull requests**: Run tests only (no deployment)
- **Main branch pushes**: Run tests + deploy

### Rollbacks
- Backend rollback: Use `backend/infra/scripts/ci-cd/rollback.sh`
- Frontend rollback: Use S3 versioning or previous deployment

## 📝 Best Practices

1. **Test locally** before pushing
2. **Review changes** in pull requests
3. **Monitor deployments** in GitHub Actions
4. **Keep secrets secure** and rotate regularly
5. **Use environment-specific** configurations

## 🐛 Troubleshooting

### Common Issues

1. **Backend deployment fails**
   - Check AWS credentials
   - Verify IAM permissions
   - Review Lambda function logs

2. **Frontend deployment fails**
   - Check S3 bucket permissions
   - Verify bucket name in secrets
   - Review S3 access logs

3. **Tests fail**
   - Run tests locally first
   - Check for environment differences
   - Review test configuration

### Debug Commands
```bash
# Test backend locally
cd backend/infra/scripts/testing
./test-api.sh

# Test frontend locally
cd web
npm test
npm run build

# Deploy frontend manually
cd web && npm run build
aws s3 sync build/ s3://your-bucket-name --delete
```

## 🌐 Website URLs

After deployment, your website will be available at:
- **S3 Website URL**: `http://your-bucket-name.s3-website-region.amazonaws.com`
- **Custom Domain**: If configured with CloudFront and Route 53 