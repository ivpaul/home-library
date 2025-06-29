const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    try {
        // Parse the request body
        const body = JSON.parse(event.body);
        // Accept ISBN from pathParameters if not present in body
        let isbn = body.isbn;
        if (!isbn && event.pathParameters && event.pathParameters.isbn) {
            isbn = event.pathParameters.isbn;
        }
        
        const { status, available, notes, title, authorFirstName, authorLastName } = body;
        
        if (!isbn) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'ISBN is required'
                })
            };
        }
        
        // Build update expression
        let updateExpression = 'SET ';
        let expressionAttributeValues = {};
        let expressionAttributeNames = {};
        
        // Handle available field (either from 'available' or 'status')
        let availableValue = undefined;
        if (available !== undefined) {
            availableValue = available;
        } else if (status !== undefined) {
            availableValue = status === 'available' ? 1 : 0;
        }
        
        if (availableValue !== undefined) {
            updateExpression += '#available = :available';
            expressionAttributeNames['#available'] = 'available';
            expressionAttributeValues[':available'] = availableValue;
        }
        
        // Handle other fields
        if (title !== undefined) {
            if (availableValue !== undefined) {
                updateExpression += ', ';
            }
            updateExpression += '#title = :title';
            expressionAttributeNames['#title'] = 'title';
            expressionAttributeValues[':title'] = title;
        }
        
        if (authorFirstName !== undefined) {
            if (updateExpression !== 'SET ') {
                updateExpression += ', ';
            }
            updateExpression += '#authorFirstName = :authorFirstName';
            expressionAttributeNames['#authorFirstName'] = 'authorFirstName';
            expressionAttributeValues[':authorFirstName'] = authorFirstName;
        }
        
        if (authorLastName !== undefined) {
            if (updateExpression !== 'SET ') {
                updateExpression += ', ';
            }
            updateExpression += '#authorLastName = :authorLastName';
            expressionAttributeNames['#authorLastName'] = 'authorLastName';
            expressionAttributeValues[':authorLastName'] = authorLastName;
        }
        
        if (notes !== undefined) {
            if (updateExpression !== 'SET ') {
                updateExpression += ', ';
            }
            updateExpression += '#notes = :notes';
            expressionAttributeNames['#notes'] = 'notes';
            expressionAttributeValues[':notes'] = notes;
        }
        
        const params = {
            TableName: 'HomeLibraryBooks',
            Key: {
                isbn: isbn
            },
            UpdateExpression: updateExpression,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        };
        
        const result = await dynamodb.update(params).promise();
        
        // Transform the response to match frontend expectations
        const updatedBook = {
            id: result.Attributes.isbn,
            title: result.Attributes.title,
            authors: `${result.Attributes.authorFirstName} ${result.Attributes.authorLastName}`,
            authorFirstName: result.Attributes.authorFirstName,
            authorLastName: result.Attributes.authorLastName,
            isbn: result.Attributes.isbn,
            status: result.Attributes.available === 1 ? 'available' : 'borrowed',
            available: result.Attributes.available,
            notes: result.Attributes.notes || ''
        };
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
            },
            body: JSON.stringify(updatedBook)
        };
        
    } catch (error) {
        console.error('Error updating book:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Failed to update book',
                message: error.message
            })
        };
    }
}; 