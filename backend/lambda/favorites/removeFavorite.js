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
            name: claims.name
        };
    } catch (error) {
        console.error('Error extracting user info:', error);
        return null;
    }
};

exports.handler = async (event) => {
    try {
        // Get user information
        const userInfo = getUserInfo(event);
        
        if (!userInfo) {
            return {
                statusCode: 401,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ error: 'Authentication required' })
            };
        }

        // Get ISBN from path parameters
        const isbn = event.pathParameters?.isbn;

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

        // Remove from favorites
        const params = {
            TableName: 'UserFavorites',
            Key: {
                userId: userInfo.userId,
                isbn: isbn
            }
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
            body: JSON.stringify({ message: 'Book removed from favorites' })
        };

    } catch (error) {
        console.error('Error removing favorite:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ error: 'Failed to remove favorite', message: error.message })
        };
    }
}; 