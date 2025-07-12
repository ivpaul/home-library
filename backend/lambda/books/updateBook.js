const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Helper function to get user info from Cognito JWT
const getUserInfo = (event) => {
    try {
        if (!event.requestContext || !event.requestContext.authorizer || !event.requestContext.authorizer.claims) {
            return null;
        }

        const claims = event.requestContext.authorizer.claims;

        return {
            userId: claims.sub,
            email: claims.email,
            name: claims.name,
            groups: claims['cognito:groups'] || []
        };
    } catch (error) {
        console.error('Error extracting user info:', error);
        return null;
    }
};

// Helper function to check if user is admin
const isAdmin = (userInfo) => {
    if (!userInfo) return false;
    return userInfo.groups.includes('admin');
};

exports.handler = async (event) => {
    // Handle CORS preflight request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ message: 'CORS preflight OK' })
        };
    }

    try {
        console.log('Event received:', JSON.stringify(event, null, 2));
        
        const userInfo = getUserInfo(event);
        console.log('User info:', JSON.stringify(userInfo, null, 2));

        if (!isAdmin(userInfo)) {
            return {
                statusCode: 403,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ error: 'Access denied. Admin privileges required to update books.' })
            };
        }

        let bookData = {};
        if (event.body) {
            bookData = JSON.parse(event.body);
        } else if (event.bookData) {
            bookData = event.bookData;
        }

        console.log('Book data:', JSON.stringify(bookData, null, 2));

        let isbn = bookData.isbn || (event.pathParameters && event.pathParameters.isbn);
        console.log('ISBN:', isbn);
        
        if (!isbn) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ error: 'ISBN is required' })
            };
        }

        // Simple update - just update the available field if provided
        const updateData = {};
        if (bookData.available !== undefined) {
            updateData.available = bookData.available;
        }
        if (bookData.notes !== undefined) {
            updateData.notes = bookData.notes;
        }
        if (bookData.title !== undefined) {
            updateData.title = bookData.title;
        }
        
        updateData.updatedAt = new Date().toISOString();

        console.log('Update data:', JSON.stringify(updateData, null, 2));

        const params = {
            TableName: 'HomeLibraryBooks',
            Key: { isbn: isbn },
            UpdateExpression: 'SET available = :available, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':available': updateData.available !== undefined ? updateData.available : 1,
                ':updatedAt': updateData.updatedAt
            },
            ReturnValues: 'ALL_NEW'
        };

        console.log('DynamoDB params:', JSON.stringify(params, null, 2));

        const result = await dynamodb.update(params).promise();
        console.log('DynamoDB result:', JSON.stringify(result, null, 2));
        
        const attributes = result.Attributes || {};

        const updatedBook = {
            id: attributes.isbn,
            title: attributes.title || '',
            authors: attributes.authorFirstName && attributes.authorLastName
                ? `${attributes.authorFirstName} ${attributes.authorLastName}`
                : attributes.authorFirstName || attributes.authorLastName || '',
            authorFirstName: attributes.authorFirstName || '',
            authorLastName: attributes.authorLastName || '',
            isbn: attributes.isbn,
            status: attributes.available === 1 ? 'available' : 'borrowed',
            available: attributes.available,
            notes: attributes.notes || '',
            updatedAt: attributes.updatedAt
        };

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify(updatedBook)
        };
    } catch (error) {
        console.error('Error updating book:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ error: 'Failed to update book', message: error.message })
        };
    }
};