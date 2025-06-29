const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    try {
        // Get ISBN from path parameters
        const isbn = event.pathParameters?.isbn;
        
        if (!isbn) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'ISBN is required',
                    event: event
                })
            };
        }
        
        const params = {
            TableName: 'HomeLibraryBooks',
            Key: {
                isbn: isbn
            }
        };
        
        const result = await dynamodb.get(params).promise();
        
        if (!result.Item) {
            return {
                statusCode: 404,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'Book not found'
                })
            };
        }
        
        // Transform the data to match your frontend expectations
        const book = {
            id: result.Item.isbn,
            title: result.Item.title,
            authors: `${result.Item.authorFirstName} ${result.Item.authorLastName}`,
            authorFirstName: result.Item.authorFirstName,
            authorLastName: result.Item.authorLastName,
            isbn: result.Item.isbn,
            status: result.Item.available === 1 ? 'available' : 'borrowed',
            available: result.Item.available,
            notes: result.Item.notes || ''
        };
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
            },
            body: JSON.stringify(book)
        };
        
    } catch (error) {
        console.error('Error getting book:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Failed to get book',
                message: error.message
            })
        };
    }
}; 