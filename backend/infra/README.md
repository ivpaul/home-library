# Infrastructure Directory

This directory contains all the infrastructure scripts and configuration files for the Home Library System AWS backend.

## 📁 Directory Structure

```
infra/
├── scripts/
│   ├── ci-cd/           # CI/CD and deployment orchestration
│   │   ├── deploy.sh    # Main deployment script
│   │   ├── backup.sh    # Create backups before deployment
│   │   └── rollback.sh  # Rollback to previous version
│   ├── deployment/      # Infrastructure deployment scripts
│   │   ├── create-dynamodb-table.sh
│   │   ├── create-api-gateway.sh
│   │   ├── deploy-lambda.sh
│   │   └── setup-iam-permissions.sh
│   ├── testing/         # Testing and validation scripts
│   │   ├── test-api.sh
│   │   ├── test-lambda.sh
│   │   ├── test-get-item.sh
│   │   └── verify-data.sh
│   └── maintenance/     # Maintenance and troubleshooting scripts
│       ├── fix-cors.sh
│       ├── upgrade-nodejs.sh
│       ├── fix-api-gateway.sh
│       └── check-api-config.sh
├── config/
│   ├── api-gateway/     # API Gateway configuration files
│   ├── dynamodb/        # DynamoDB configuration files
│   └── lambda/          # Lambda configuration files
└── README.md           # This file
```

## 🚀 Quick Start

### For Development
```bash
# Deploy everything from scratch
cd scripts/ci-cd
./deploy.sh

# Test the deployment
cd ../testing
./test-api.sh
```

### For CI/CD
The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically:
1. Runs tests on pull requests
2. Creates backups before deployment
3. Deploys to production on main branch pushes
4. Runs post-deployment tests

## 📋 Script Categories

### CI/CD Scripts (`scripts/ci-cd/`)
- **`deploy.sh`**: Orchestrates the complete deployment process
- **`backup.sh`**: Creates backups before deployment
- **`rollback.sh`**: Rolls back to previous version if needed

### Deployment Scripts (`scripts/deployment/`)
- **`create-dynamodb-table.sh`**: Creates the DynamoDB table
- **`create-api-gateway.sh`**: Sets up API Gateway with all endpoints
- **`deploy-lambda.sh`**: Deploys all Lambda functions
- **`setup-iam-permissions.sh`**: Configures IAM roles and policies

### Testing Scripts (`scripts/testing/`)
- **`test-api.sh`**: Tests all API Gateway endpoints
- **`test-lambda.sh`**: Tests Lambda functions directly
- **`test-get-item.sh`**: Tests DynamoDB operations
- **`verify-data.sh`**: Verifies data integrity

### Maintenance Scripts (`scripts/maintenance/`)
- **`fix-cors.sh`**: Fixes CORS configuration
- **`upgrade-nodejs.sh`**: Upgrades Lambda runtime versions
- **`fix-api-gateway.sh`**: Fixes API Gateway configuration issues
- **`check-api-config.sh`**: Checks API Gateway configuration

## 🔧 Usage Examples

### Deploy Everything
```bash
cd scripts/ci-cd
./deploy.sh
```

### Test Only
```bash
cd scripts/testing
./test-api.sh
```

### Fix CORS Issues
```bash
cd scripts/maintenance
./fix-cors.sh
```

### Upgrade Node.js Runtime
```bash
cd scripts/maintenance
./upgrade-nodejs.sh
```

### Create Backup
```bash
cd scripts/ci-cd
./backup.sh
```

### Rollback Deployment
```bash
cd scripts/ci-cd
./rollback.sh
```

## 🔐 Security

### Required AWS Permissions
Your AWS user/role needs permissions for:
- **Lambda**: Create, update, delete functions
- **DynamoDB**: Create, read, write, delete tables and items
- **API Gateway**: Create, update, delete APIs and resources
- **IAM**: Create and manage roles and policies
- **CloudWatch**: Read logs

### Environment Variables
- `AWS_REGION`: AWS region (default: us-east-1)
- `ENVIRONMENT`: Environment name (default: prod)
- `AWS_ACCESS_KEY_ID`: AWS access key (for CI/CD)
- `AWS_SECRET_ACCESS_KEY`: AWS secret key (for CI/CD)

## 🐛 Troubleshooting

### Common Issues

1. **CORS Errors**: Run `scripts/maintenance/fix-cors.sh`
2. **API Gateway 500 Errors**: Check Lambda function logs
3. **Permission Denied**: Verify IAM roles and policies
4. **Deployment Failures**: Check AWS CLI configuration

### Debug Commands
```bash
# Check API Gateway configuration
cd scripts/maintenance
./check-api-config.sh

# Test Lambda functions directly
cd scripts/testing
./test-lambda.sh

# Verify DynamoDB data
cd scripts/testing
./verify-data.sh
```

## 📝 Best Practices

1. **Always create backups** before major deployments
2. **Test in staging** before deploying to production
3. **Use environment variables** for configuration
4. **Monitor logs** after deployments
5. **Keep scripts organized** in appropriate directories

## 🔄 CI/CD Integration

The GitHub Actions workflow automatically:
- Runs on pushes to main branch
- Only triggers when backend files change
- Creates backups before deployment
- Runs comprehensive tests
- Provides deployment status feedback

## 📞 Support

For issues with infrastructure deployment:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Run the appropriate maintenance scripts
4. Check GitHub Actions logs for CI/CD issues 