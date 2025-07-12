import axios from 'axios';
import { userPool } from '../contexts/AuthContext';

// API Configuration
const API_BASE_URL = process.env.REACT_APP_API_GATEWAY_URL;

class ApiService {
  constructor() {
    this.api = axios.create({
      baseURL: API_BASE_URL,
      headers: { 'Content-Type': 'application/json' },
    });

    // Request interceptor to add Authorization header if logged in
    this.api.interceptors.request.use(
      async (config) => {
        try {
          const currentUser = userPool.getCurrentUser();
          
          if (currentUser) {
            // getSession is async, so wrap in a Promise
            const token = await new Promise((resolve, reject) => {
              currentUser.getSession((err, session) => {
                if (err) {
                  console.error('Error getting session:', err);
                  resolve(null);
                } else if (session && session.isValid()) {
                  const jwtToken = session.getIdToken().getJwtToken();
                  resolve(jwtToken);
                } else {
                  resolve(null);
                }
              });
            });
            
            if (token) {
              config.headers['Authorization'] = `Bearer ${token}`;
            }
          }
        } catch (error) {
          console.error('Error in request interceptor:', error);
        }
        
        return config;
      },
      (error) => {
        console.error('Request interceptor error:', error);
        return Promise.reject(error);
      }
    );

    // Response interceptor for error logging
    this.api.interceptors.response.use(
      (response) => {
        return response;
      },
      (error) => {
        console.error('API request failed:', error);
        if (error.response) {
          console.error('Response status:', error.response.status);
          console.error('Response data:', error.response.data);
          console.error('Response headers:', error.response.headers);
        }
        return Promise.reject(error);
      }
    );
  }

  // Books API - CRUD operations
  getBooks(params = {}) {
    return this.api.get('/books', { params }).then(res => res.data);
  }

  getBook(isbn) {
    return this.api.get(`/books/${isbn}`).then(res => res.data);
  }

  createBook(bookData) {
    return this.api.post('/books', bookData).then(res => res.data);
  }

  updateBook(isbn, bookData) {
    return this.api.put(`/books/${isbn}`, bookData).then(res => res.data);
  }

  deleteBook(isbn) {
    return this.api.delete(`/books/${isbn}`).then(res => res.data);
  }

  // Favorites API
  getTopBooks() {
    return this.api.get('/favorites').then(res => res.data);
  }

  addFavorite(isbn) {
    return this.api.post(`/favorites/${isbn}`).then(res => res.data);
  }

  removeFavorite(isbn) {
    return this.api.delete(`/favorites/${isbn}`).then(res => res.data);
  }

  getUserFavorites() {
    return this.api.get('/favorites').then(res => res.data.map(book => book.isbn));
  }

  // Admin Favorites API
  getAdminFavorites() {
    return this.api.get('/admin-favorites').then(res => res.data.admins);
  }

  // Helper: check if book is available
  isBookAvailable(book) {
    return book.available === 1 || book.status === 'available';
  }

  // Helper: toggle book availability
  async toggleBookAvailability(book) {
    const newAvailable = book.available === 1 ? 0 : 1;
    const action = newAvailable === 1 ? 'checked in' : 'checked out';
    try {
      await this.updateBook(book.isbn, { 
        available: newAvailable,
        notes: book.notes || ''
      });
      return { success: true, action };
    } catch (error) {
      return { success: false, error: `Failed to ${action} book` };
    }
  }
}

export default new ApiService(); 