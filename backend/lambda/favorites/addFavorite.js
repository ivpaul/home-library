const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Helper function to get user info from Cognito JWT
const getUserInfo = (event) => {
    try {
        console.log('Event received:', JSON.stringify(event, null, 2));
        
        if (!event.requestContext || !event.requestContext.authorizer || !event.requestContext.authorizer.claims) {
            console.log('No authorizer or claims found in event');
            return null;
        }
        
        const claims = event.requestContext.authorizer.claims;
        console.log('Claims found:', JSON.stringify(claims, null, 2));
        
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
        let isbn;
        if (event.pathParameters && event.pathParameters.isbn) {
            isbn = event.pathParameters.isbn;
        } else if (event.body) {
            const body = JSON.parse(event.body);
            isbn = body.isbn;
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

        // Check if user already has 3 favorites
        const existingFavoritesParams = {
            TableName: 'UserFavorites',
            KeyConditionExpression: 'userId = :userId',
            ExpressionAttributeValues: {
                ':userId': userInfo.userId
            }
        };

        const existingFavorites = await dynamodb.query(existingFavoritesParams).promise();
        
        if (existingFavorites.Items.length >= 3) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ error: 'Maximum of 3 favorites allowed' })
            };
        }

        // Check if this book is already a favorite
        const existingFavorite = existingFavorites.Items.find(item => item.isbn === isbn);
        if (existingFavorite) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ error: 'Book is already in favorites' })
            };
        }

        // Fetch book details from Books table
        const bookParams = {
            TableName: 'HomeLibraryBooks',
            Key: { isbn }
        };
        const bookResult = await dynamodb.get(bookParams).promise();
        const book = bookResult.Item;
        if (!book) {
            return {
                statusCode: 404,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ error: 'Book not found' })
            };
        }

        // Add to favorites with title and author
        const params = {
            TableName: 'UserFavorites',
            Item: {
                userId: userInfo.userId,
                isbn: isbn,
                title: book.title,
                author: book.author,
                createdAt: new Date().toISOString()
            }
        };

        await dynamodb.put(params).promise();

        return {
            statusCode: 201,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ message: 'Book added to favorites' })
        };

    } catch (error) {
        console.error('Error adding favorite:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ error: 'Failed to add favorite', message: error.message })
        };
    }
}; 