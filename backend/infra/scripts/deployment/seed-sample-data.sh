#!/bin/bash

echo "Adding sample books to DynamoDB table..."

# Sample book 1
aws dynamodb put-item \
  --table-name HomeLibraryBooks \
  --item '{
    "isbn": {"S": "9780547928240"},
    "title": {"S": "The Hobbit"},
    "authorFirstName": {"S": "J.R.R."},
    "authorLastName": {"S": "Tolkien"},
    "available": {"N": "1"}
  }' \
  --region us-east-1

# Sample book 2
aws dynamodb put-item \
  --table-name HomeLibraryBooks \
  --item '{
    "isbn": {"S": "9780547928210"},
    "title": {"S": "The Fellowship of the Ring"},
    "authorFirstName": {"S": "J.R.R."},
    "authorLastName": {"S": "Tolkien"},
    "available": {"N": "1"}
  }' \
  --region us-east-1

# Sample book 3
aws dynamodb put-item \
  --table-name HomeLibraryBooks \
  --item '{
    "isbn": {"S": "9780553103540"},
    "title": {"S": "A Game of Thrones"},
    "authorFirstName": {"S": "George"},
    "authorLastName": {"S": "Martin"},
    "available": {"N": "0"}
  }' \
  --region us-east-1

# Sample book 4
aws dynamodb put-item \
  --table-name HomeLibraryBooks \
  --item '{
    "isbn": {"S": "9780743273565"},
    "title": {"S": "The Great Gatsby"},
    "authorFirstName": {"S": "F. Scott"},
    "authorLastName": {"S": "Fitzgerald"},
    "available": {"N": "1"}
  }' \
  --region us-east-1

echo "✅ Sample data added successfully!"

# Show all items in the table
echo "Current books in the table:"
aws dynamodb scan \
  --table-name HomeLibraryBooks \
  --region us-east-1 \
  --query 'Items[].[isbn.S,title.S,authorFirstName.S,authorLastName.S,available.N]' \
  --output table 