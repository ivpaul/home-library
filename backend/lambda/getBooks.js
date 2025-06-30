const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Updated: Testing OIDC authentication for GitHub Actions deployment

// Helper function to get user info from Cognito
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
            role: claims['custom:role'] || 'member'
        };
    } catch (error) {
        console.error('Error extracting user info:', error);
        return null;
    }
};

// Helper function to check user permissions
const checkPermission = (userRole, requiredRole) => {
    const roleHierarchy = {
        'admin': 3,
        'librarian': 2,
        'member': 1
    };
    
    return roleHierarchy[userRole] >= roleHierarchy[requiredRole];
};

exports.handler = async (event) => {
    try {
        // Simple scan without user authentication for now
        const params = {
            TableName: 'HomeLibraryBooks'
        };
        
        const result = await dynamodb.scan(params).promise();
        
        // Transform the data to match your frontend expectations
        const books = result.Items.map(item => {
            // Handle different author data formats
            let authorName = '';
            if (item.author) {
                // New format: single author field
                authorName = item.author;
            } else if (item.authorFirstName && item.authorLastName) {
                // Sample data format: separate first and last name
                authorName = `${item.authorFirstName} ${item.authorLastName}`;
            } else if (item.authors) {
                // Alternative format: authors field
                authorName = item.authors;
            } else {
                authorName = 'Unknown Author';
            }

            return {
                id: item.isbn,
                title: item.title,
                author: authorName,
                authors: authorName, // For backward compatibility
                authorFirstName: item.authorFirstName,
                authorLastName: item.authorLastName,
                isbn: item.isbn,
                year: item.year,
                pages: item.pages,
                status: item.available === 1 ? 'available' : 'borrowed',
                available: item.available,
                notes: item.notes || '',
                userId: item.userId,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            };
        });
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({
                books: books,
                pagination: {
                    total: books.length
                }
            })
        };
        
    } catch (error) {
        console.error('Error getting books:', error);
        console.error('Error stack:', error.stack);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({
                error: 'Failed to get books',
                message: error.message,
                stack: error.stack
            })
        };
    }
}; 