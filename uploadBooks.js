const axios = require('axios');
const fs = require('fs');
const path = require('path');
require('dotenv').config(); // root .env
require('dotenv').config({ path: path.join(__dirname, 'web', '.env') });

// Path to books.json (adjust if necessary)
const booksPath = path.join(__dirname, 'books.json');

if (!fs.existsSync(booksPath)) {
  console.error('❌ books.json not found at', booksPath);
  process.exit(1);
}

const books = JSON.parse(fs.readFileSync(booksPath, 'utf8'));

// Expect API endpoint (base URL) and JWT token to be provided via env vars
const API_ENDPOINT = process.env.API_ENDPOINT || process.env.REACT_APP_API_GATEWAY_URL; // allow using React var
const JWT_TOKEN    = process.env.JWT_TOKEN;    // e.g. eyJraWQiOiJ....

if (!API_ENDPOINT || !JWT_TOKEN) {
  console.error('❌ Please set API_ENDPOINT and JWT_TOKEN environment variables before running.');
  process.exit(1);
}

// Helper to upload one book
async function uploadBook(book) {
  try {
    const payload = {
      isbn: book.isbn,
      title: book.title,
      authors: `${book.author_first} ${book.author_last}`,
      authorFirstName: book.author_first,
      authorLastName:  book.author_last
    };

    const res = await axios.post(`${API_ENDPOINT}/books`, payload, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${JWT_TOKEN}`
      }
    });

    console.log(`✅ Uploaded: ${book.title} (${book.isbn}) – status ${res.status}`);
  } catch (err) {
    const msg = err.response ? `${err.response.status} ${JSON.stringify(err.response.data)}` : err.message;
    console.error(`❌ Failed to upload: ${book.title} (${book.isbn}) – ${msg}`);
  }
}

(async () => {
  for (const book of books) {
    await uploadBook(book);
  }
})(); 