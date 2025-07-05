#!/bin/bash

API_ID="zit3ozv33d"

echo "🔍 Checking API Gateway Configuration..."
echo "========================================"

echo ""
echo "1. Checking API Gateway resources:"
echo "----------------------------------"
aws apigateway get-resources --rest-api-id $API_ID --query 'items[].{Path:path,ID:id,ParentID:parentId}' --output table

echo ""
echo "2. Getting all resources (raw):"
echo "-------------------------------"
aws apigateway get-resources --rest-api-id $API_ID

echo ""
echo "3. Checking methods on /books resource:"
echo "---------------------------------------"
BOOKS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`books`].id' --output text)
echo "Books resource ID: $BOOKS_ID"
if [ ! -z "$BOOKS_ID" ] && [ "$BOOKS_ID" != "None" ]; then
    echo "GET method:"
    aws apigateway get-method --rest-api-id $API_ID --resource-id $BOOKS_ID --http-method GET
    echo ""
    echo "POST method:"
    aws apigateway get-method --rest-api-id $API_ID --resource-id $BOOKS_ID --http-method POST
else
    echo "❌ /books resource not found"
fi

echo ""
echo "4. Checking methods on /books/{isbn} resource:"
echo "----------------------------------------------"
BOOK_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`{isbn}`].id' --output text)
echo "Book resource ID: $BOOK_ID"
if [ ! -z "$BOOK_ID" ] && [ "$BOOK_ID" != "None" ]; then
    echo "GET method:"
    aws apigateway get-method --rest-api-id $API_ID --resource-id $BOOK_ID --http-method GET 2>/dev/null || echo "❌ GET method not found"
    echo ""
    echo "PUT method:"
    aws apigateway get-method --rest-api-id $API_ID --resource-id $BOOK_ID --http-method PUT 2>/dev/null || echo "❌ PUT method not found"
    echo ""
    echo "DELETE method:"
    aws apigateway get-method --rest-api-id $API_ID --resource-id $BOOK_ID --http-method DELETE 2>/dev/null || echo "❌ DELETE method not found"
else
    echo "❌ /books/{isbn} resource not found"
fi

echo ""
echo "5. Checking Lambda function permissions:"
echo "----------------------------------------"
aws lambda get-policy --function-name HomeLibraryGetBook 2>/dev/null || echo "❌ No policy found for HomeLibraryGetBook"

echo ""
echo "6. Testing endpoints:"
echo "--------------------"
echo "Testing GET /books (should work):"
curl -s https://$API_ID.execute-api.us-east-1.amazonaws.com/prod/books | head -c 100
echo ""

echo "Testing GET /books/{isbn} (might fail):"
curl -s https://$API_ID.execute-api.us-east-1.amazonaws.com/prod/books/9780061120084 | head -c 100
echo ""

echo "✅ Configuration check complete!" 