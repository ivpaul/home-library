#!/bin/bash

echo "🚀 Setting up local development environment..."

# Check if config.json already exists
if [ -f "backend/infra/scripts/deployment/config.json" ]; then
    echo "✅ config.json already exists with your values"
else
    echo "⚠️  config.json not found. Please create it with your AWS resource IDs:"
    echo "   - Cognito User Pool ID"
    echo "   - Cognito Client ID" 
    echo "   - Cognito Identity Pool ID"
    echo "   - API Gateway ID and URL"
    echo "   - DynamoDB table name"
fi

# Check if .env exists
if [ -f "web/.env" ]; then
    echo "✅ web/.env already exists"
else
    echo "📝 Creating web/.env..."
    cat > web/.env << EOF
REACT_APP_COGNITO_USER_POOL_ID=your_user_pool_id_here
REACT_APP_COGNITO_CLIENT_ID=your_client_id_here
REACT_APP_API_GATEWAY_URL=your_api_gateway_url_here
EOF
    echo "⚠️  Please edit web/.env with your actual Cognito and API Gateway values"
fi

echo ""
echo "📋 Next steps:"
echo "1. Ensure backend/infra/scripts/deployment/config.json exists with your AWS resource IDs"
echo "2. Edit web/.env with your Cognito and API Gateway values"
echo "3. Run 'npm start' in the web directory to start the React app"
echo ""
echo "💡 Your current values (if config.json exists):"
if [ -f "backend/infra/scripts/deployment/config.json" ]; then
    echo "   Cognito User Pool ID: $(jq -r '.cognito.userPoolId' backend/infra/scripts/deployment/config.json)"
    echo "   Cognito Client ID: $(jq -r '.cognito.clientId' backend/infra/scripts/deployment/config.json)"
    echo "   API Gateway URL: $(jq -r '.apiGateway.url' backend/infra/scripts/deployment/config.json)"
fi 