# Home Library System

A modern web application for managing your home book collection, built with React frontend and AWS serverless backend.

## 🎯 What This App Does

- **View your book collection** in a clean, organized layout
- **Add new books** to your library with title, author, ISBN, and more
- **Check books in/out** to track which ones are available or borrowed
- **Add notes** to each book for personal thoughts and reminders
- **Delete books** from your collection
- **Search** your collection by title or author

## 🏗️ Project Structure

```
home-library-system/
├── web/                    # React web application
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── screens/        # Main app screens
│   │   ├── services/       # API service layer
│   │   └── theme.js        # Material-UI theme
│   ├── public/             # Static files
│   └── package.json        # Web app dependencies
├── backend/                # AWS serverless backend
│   ├── lambda/             # Lambda functions
│   │   ├── getBooks.js     # Get all books
│   │   ├── getBook.js      # Get single book by ISBN
│   │   ├── createBook.js   # Create new book
│   │   ├── updateBook.js   # Update book details
│   │   ├── deleteBook.js   # Delete book
│   │   └── package.json    # Lambda dependencies
│   └── infra/              # Infrastructure scripts
│       ├── *.sh            # AWS deployment scripts
│       └── *.json          # AWS configuration files
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

- Node.js (version 16 or higher)
- AWS CLI configured with appropriate permissions
- AWS account with access to Lambda, DynamoDB, and API Gateway

### 1. Start the Web App

```bash
cd web
npm install
npm start
```

### 2. Open Your Browser
Navigate to `http://localhost:3000`

## 🔧 Backend Infrastructure

The backend is built on AWS serverless architecture:

- **DynamoDB**: NoSQL database for storing book data
- **Lambda**: Serverless functions for CRUD operations
- **API Gateway**: RESTful API endpoints
- **IAM**: Security and permissions management

### Configuration Management

The project uses a consolidated `config.json` file for all AWS resource IDs and configuration:

```json
{
  "aws": {
    "region": "us-east-1",
    "environment": "prod"
  },
  "cognito": {
    "userPoolId": "your-user-pool-id",
    "clientId": "your-client-id",
    "identityPoolId": "your-identity-pool-id"
  },
  "apiGateway": {
    "id": "your-api-gateway-id",
    "url": "your-api-gateway-url"
  },
  "dynamodb": {
    "tableName": "your-dynamodb-table-name"
  }
}
```

**Benefits:**
- ✅ Single source of truth for all configuration
- ✅ Easy to manage different environments
- ✅ No scattered `.id` files
- ✅ Version controlled and trackable changes

### API Endpoints

- `GET /books` - Get all books
- `GET /books/{isbn}` - Get book by ISBN
- `POST /books` - Create new book
- `PUT /books/{isbn}` - Update book
- `DELETE /books/{isbn}` - Delete book

## 📝 Features

### Book Collection Management
- **Add Books**: Create new entries with title, author, ISBN, publication year, pages, and notes
- **View Books**: Responsive grid layout showing all book information
- **Edit Books**: Update book details and availability status
- **Delete Books**: Remove books from your collection with confirmation

### Check In/Out System
- **One-click status updates** for book availability
- **Visual feedback** with color-coded buttons
- **Toast notifications** for all actions

### Notes Management
- **Add/edit personal notes** for each book
- **Multi-line text support**
- **Auto-save functionality**

### Search & Filter
- **Real-time search** by title or author
- **Instant filtering results**

## 🎨 Tech Stack

### Frontend
- **React 18** - Modern React with hooks
- **Material-UI (MUI)** - Component library for consistent design
- **Axios** - HTTP client for API communication
- **React Hot Toast** - Toast notifications

### Backend
- **AWS Lambda** - Serverless functions (Node.js 20.x)
- **AWS DynamoDB** - NoSQL database
- **AWS API Gateway** - REST API
- **AWS IAM** - Security and permissions

## 📱 Responsive Design

Works perfectly on:
- Desktop computers
- Tablets
- Mobile phones

## 🔄 Data Storage

Uses AWS DynamoDB for persistent, scalable data storage. Your book collection is safely stored in the cloud and accessible from anywhere.

## 🚀 Deployment

### Frontend Deployment

The React app can be deployed to:
- **Netlify**: Connect your GitHub repo and auto-deploy
- **Vercel**: Similar to Netlify with excellent React support
- **AWS S3 + CloudFront**: For AWS-native hosting
- **GitHub Pages**: Free hosting for public repositories

### Backend Deployment

The backend is already deployed on AWS. To update Lambda functions:

```bash
cd backend/lambda
zip -r functionName.zip functionName.js node_modules package.json
cd ../infra
./deploy-lambda.sh
```

## 🔧 Development

### Local Development
- **Frontend**: `http://localhost:3000`
- **Backend**: AWS API Gateway (no local setup needed)

### Environment Variables
The frontend connects to your AWS API Gateway. Update the API URL in `web/src/services/api.js` if needed.

### Environment Variables

Create a `.env` file in the `web/` directory with the following variables:

```bash
# Cognito Configuration
REACT_APP_COGNITO_USER_POOL_ID=your-user-pool-id-here
REACT_APP_COGNITO_CLIENT_ID=your-client-id-here
```

**Note**: The `.env` file is already in `.gitignore` to keep your credentials secure. Never commit this file to version control.

## 📄 License

MIT License 