#!/bin/bash

echo "Verifying data in HomeLibraryBooks table..."

# Scan the table and show results
aws dynamodb scan \
  --table-name HomeLibraryBooks \
  --region us-east-1 \
  --query 'Items[].[isbn.S,title.S,authorFirstName.S,authorLastName.S,available.N]' \
  --output table

echo ""
echo "Total items in table:"
aws dynamodb scan \
  --table-name HomeLibraryBooks \
  --region us-east-1 \
  --select COUNT 