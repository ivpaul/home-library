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
                body: JSON.stringify({ error: 'Access denied. Admin privileges required to create books.' })
            };
        }
        
        // Parse the request body (API Gateway proxy event)
        let bookData;
        if (event.body) {
            bookData = JSON.parse(event.body);
        } else if (event.bookData) {
            bookData = event.bookData;
        }
        
        if (!bookData || !bookData.isbn || !bookData.title || (!bookData.author && !bookData.authors)) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ 
                    error: 'Missing required fields. Please provide: isbn, title, author/authors' 
                })
            };
        }

        // Handle author data - prefer authors field, fallback to author
        const authorName = bookData.authors || bookData.author;
        const authorParts = authorName.split(' ');
        const authorFirstName = authorParts[0] || '';
        const authorLastName = authorParts.slice(1).join(' ') || '';

        const currentTime = new Date().toISOString();
        
        const params = {
            TableName: 'HomeLibraryBooks',
            Item: {
                isbn: bookData.isbn,
                title: bookData.title,
                author: authorName,
                authors: authorName, // Store both for consistency
                authorFirstName: bookData.authorFirstName || authorFirstName,
                authorLastName: bookData.authorLastName || authorLastName,
                year: bookData.year || bookData.publication_date ? new Date(bookData.publication_date).getFullYear() : null,
                pages: bookData.pages || null,
                available: bookData.available !== undefined ? bookData.available : 1,
                notes: bookData.notes || '',
                createdAt: currentTime,
                updatedAt: currentTime
            }
        };

        await dynamodb.put(params).promise();

        // Transform the response to match frontend expectations
        const createdBook = {
            id: params.Item.isbn,
            title: params.Item.title,
            author: params.Item.author,
            authors: params.Item.authors,
            authorFirstName: params.Item.authorFirstName,
            authorLastName: params.Item.authorLastName,
            isbn: params.Item.isbn,
            year: params.Item.year,
            pages: params.Item.pages,
            status: params.Item.available === 1 ? 'available' : 'borrowed',
            available: params.Item.available,
            notes: params.Item.notes,
            createdAt: params.Item.createdAt,
            updatedAt: params.Item.updatedAt
        };

        return {
            statusCode: 201,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify(createdBook)
        };
    } catch (error) {
        console.error('Error creating book:', error);
        
        if (error.code === 'ConditionalCheckFailedException') {
            return {
                statusCode: 409,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({ 
                    error: 'Book with this ISBN already exists' 
                })
            };
        }
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({ 
                error: 'Failed to create book', 
                message: error.message 
            })
        };
    }
}; 