#!/bin/bash

API_ID="zit3ozv33d"
BASE_URL="https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"
ISBN="9780061120084"

# Test GET /books
echo "\n===== GET /books ====="
curl -s -X GET "$BASE_URL/books" | jq

# Test POST /books
echo "\n===== POST /books ====="
POST_DATA='{"isbn":"9780140328721","title":"Matilda","authorFirstName":"Roald","authorLastName":"Dahl","available":1,"notes":"Classic"}'
curl -s -X POST "$BASE_URL/books" -H "Content-Type: application/json" -d "$POST_DATA" | jq

# Test GET /books/{isbn}
echo "\n===== GET /books/{isbn} ====="
curl -s -X GET "$BASE_URL/books/$ISBN" | jq

# Test PUT /books/{isbn}
echo "\n===== PUT /books/{isbn} ====="
PUT_DATA='{"title":"To Kill a Mockingbird (Updated)","authorFirstName":"Harper","authorLastName":"Lee","available":0,"notes":"Checked out"}'
curl -s -X PUT "$BASE_URL/books/$ISBN" -H "Content-Type: application/json" -d "$PUT_DATA" | jq

# Test DELETE /books/{isbn}
echo "\n===== DELETE /books/{isbn} ====="
DELETE_DATA='{"isbn":"$ISBN"}'
curl -s -X DELETE "$BASE_URL/books/$ISBN" -H "Content-Type: application/json" -d "$DELETE_DATA" | jq

echo "✅ API testing completed!" 