const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const cognito = new AWS.CognitoIdentityServiceProvider();

const USER_POOL_ID = process.env.REACT_APP_COGNITO_USER_POOL_ID;
const ADMIN_GROUP = 'admin';

const corsHeaders = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
};

exports.handler = async (event) => {
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({ message: 'CORS preflight' })
        };
    }
    try {
        console.log('Getting admin favorites...');

        // 1. Get all admin users from Cognito
        const adminsResult = await cognito.listUsersInGroup({
            UserPoolId: USER_POOL_ID,
            GroupName: ADMIN_GROUP
        }).promise();

        console.log(`Found ${adminsResult.Users.length} admin users`);

        // Extract admin user info (username and sub)
        const adminUsers = adminsResult.Users.map(user => {
            const subAttr = user.Attributes.find(attr => attr.Name === 'sub');
            const nameAttr = user.Attributes.find(attr => attr.Name === 'name');
            const emailAttr = user.Attributes.find(attr => attr.Name === 'email');
            const preferredUsernameAttr = user.Attributes.find(attr => attr.Name === 'preferred_username');
            
            // Determine display name with priority: name > email > preferred_username > shortened UUID
            let displayName = 'Unknown';
            if (nameAttr && nameAttr.Value) {
                displayName = nameAttr.Value;
            } else if (emailAttr && emailAttr.Value) {
                displayName = emailAttr.Value;
            } else if (preferredUsernameAttr && preferredUsernameAttr.Value) {
                displayName = preferredUsernameAttr.Value;
            } else if (user.Username) {
                displayName = user.Username;
            } else if (subAttr && subAttr.Value) {
                // Fallback to shortened UUID (first 8 characters)
                displayName = subAttr.Value.substring(0, 8);
            }
            
            return {
                userId: subAttr ? subAttr.Value : null,
                username: displayName
            };
        }).filter(u => u.userId !== null);

        if (adminUsers.length === 0) {
            return {
                statusCode: 200,
                headers: corsHeaders,
                body: JSON.stringify({ admins: [] })
            };
        }

        // For each admin, get their favorites and book details
        const adminFavorites = [];
        for (const admin of adminUsers) {
            const favoritesResult = await dynamodb.query({
                TableName: 'UserFavorites',
                KeyConditionExpression: 'userId = :userId',
                ExpressionAttributeValues: { ':userId': admin.userId }
            }).promise();
            const favoriteIsbns = favoritesResult.Items.map(fav => fav.isbn);
            // Get book details for each favorite
            const bookPromises = favoriteIsbns.map(async (isbn) => {
                const bookResult = await dynamodb.get({
                    TableName: 'HomeLibraryBooks',
                    Key: { isbn }
                }).promise();
                if (bookResult.Item) {
                    let authorName = '';
                    if (bookResult.Item.author) {
                        authorName = bookResult.Item.author;
                    } else if (bookResult.Item.authorFirstName && bookResult.Item.authorLastName) {
                        authorName = `${bookResult.Item.authorFirstName} ${bookResult.Item.authorLastName}`;
                    } else if (bookResult.Item.authors) {
                        authorName = bookResult.Item.authors;
                    } else {
                        authorName = 'Unknown Author';
                    }
                    return {
                        id: bookResult.Item.isbn,
                        title: bookResult.Item.title,
                        author: authorName,
                        authors: authorName,
                        authorFirstName: bookResult.Item.authorFirstName,
                        authorLastName: bookResult.Item.authorLastName,
                        isbn: bookResult.Item.isbn,
                        year: bookResult.Item.year,
                        pages: bookResult.Item.pages,
                        status: bookResult.Item.available === 1 ? 'available' : 'borrowed',
                        available: bookResult.Item.available,
                        notes: bookResult.Item.notes || '',
                        isFavorite: false
                    };
                }
                return null;
            });
            const books = (await Promise.all(bookPromises)).filter(book => book !== null);
            adminFavorites.push({
                username: admin.username,
                favorites: books
            });
        }

        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({ admins: adminFavorites })
        };

    } catch (error) {
        console.error('Error getting admin favorites:', error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ 
                error: 'Failed to get admin favorites', 
                message: error.message 
            })
        };
    }
}; 