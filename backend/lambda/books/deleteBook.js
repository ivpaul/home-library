const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Helper function to get user info from Cognito JWT
const getUserInfo = (event) => {
    try {
        // Check if authorizer exists (user is authenticated)
        if (!event.requestContext || !event.requestContext.authorizer || !event.requestContext.authorizer.claims) {
            return null; // No authentication
        }
        
        // Extract user info from Cognito JWT token
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
    try {
        // Get user information
        const userInfo = getUserInfo(event);
        
        // Check if user is admin
        if (!isAdmin(userInfo)) {
                    return {
            statusCode: 403,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ error: 'Access denied. Admin privileges required to delete books.' })
        };
        }
        
        // Extract ISBN from API Gateway path parameters
        let isbn;
        if (event.pathParameters && event.pathParameters.isbn) {
            isbn = event.pathParameters.isbn;
        } else if (event.body) {
            const body = JSON.parse(event.body);
            isbn = body.isbn;
        } else if (event.isbn) {
            isbn = event.isbn;
        }
        
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

        const params = {
            TableName: 'HomeLibraryBooks',
            Key: { isbn }
        };

        await dynamodb.delete(params).promise();

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ message: `Book with ISBN ${isbn} deleted.` })
        };
    } catch (error) {
        console.error('Error deleting book:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ error: 'Failed to delete book', message: error.message })
        };
    }
}; 