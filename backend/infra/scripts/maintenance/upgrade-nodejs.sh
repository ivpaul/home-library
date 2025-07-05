#!/bin/bash

echo "🚀 Upgrading Lambda functions from Node.js 18 to Node.js 20..."
echo "=========================================================="

# List of all Lambda functions
FUNCTIONS=(
  "HomeLibraryGetBooks"
  "HomeLibraryCreateBook"
  "HomeLibraryUpdateBook"
  "HomeLibraryDeleteBook"
  "HomeLibraryGetBook"
)

# Update each function
for function in "${FUNCTIONS[@]}"; do
  echo "Updating $function..."
  
  aws lambda update-function-configuration \
    --function-name "$function" \
    --runtime "nodejs20.x" \
    --no-cli-pager
  
  if [ $? -eq 0 ]; then
    echo "✅ Successfully updated $function to Node.js 20"
  else
    echo "❌ Failed to update $function"
  fi
done

echo ""
echo "🎉 Node.js upgrade complete!"
echo "All Lambda functions are now running on Node.js 20.x"
echo ""
echo "📋 Summary of changes:"
echo "- Node.js 18.x → Node.js 20.x"
echo "- Extended support until April 2026"
echo "- Better performance and security"
echo "- Latest ES2022 features" 