import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Typography,
  Alert,
  Box,
  Grid,
} from '@mui/material';
import apiService from '../services/api';
import toast from 'react-hot-toast';

const CreateBookModal = ({ open, onClose, onBookCreated }) => {
  const [formData, setFormData] = useState({
    title: '',
    authors: '',
    isbn: '',
    publication_date: '',
    pages: '',
    notes: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleInputChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Validate required fields
      if (!formData.title || !formData.authors || !formData.isbn) {
        throw new Error('Title, Authors, and ISBN are required');
      }

      // Format the data for the API
      const bookData = {
        title: formData.title,
        authors: formData.authors,
        author: formData.authors, // For backward compatibility
        authorFirstName: formData.authors.split(' ')[0] || '',
        authorLastName: formData.authors.split(' ').slice(1).join(' ') || '',
        isbn: formData.isbn,
        publication_date: formData.publication_date || null,
        pages: formData.pages ? parseInt(formData.pages) : null,
        notes: formData.notes || '',
        available: 1,
        status: 'available'
      };

      await apiService.createBook(bookData);
      
      toast.success('Book created successfully!');
      onBookCreated();
      onClose();
      
      // Reset form
      setFormData({
        title: '',
        authors: '',
        isbn: '',
        publication_date: '',
        pages: '',
        notes: ''
      });
    } catch (error) {
      console.error('Error creating book:', error);
      setError(error.message || 'Failed to create book');
      toast.error('Failed to create book');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Add New Book</DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Enter the details for the new book
          </Typography>
          
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Title *"
                value={formData.title}
                onChange={(e) => handleInputChange('title', e.target.value)}
                required
                disabled={loading}
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Authors *"
                value={formData.authors}
                onChange={(e) => handleInputChange('authors', e.target.value)}
                placeholder="e.g., J.K. Rowling, Stephen King"
                required
                disabled={loading}
              />
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="ISBN *"
                value={formData.isbn}
                onChange={(e) => handleInputChange('isbn', e.target.value)}
                placeholder="e.g., 9780061120084"
                required
                disabled={loading}
              />
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Publication Date"
                type="date"
                value={formData.publication_date}
                onChange={(e) => handleInputChange('publication_date', e.target.value)}
                InputLabelProps={{ shrink: true }}
                disabled={loading}
              />
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Pages"
                type="number"
                value={formData.pages}
                onChange={(e) => handleInputChange('pages', e.target.value)}
                disabled={loading}
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Notes"
                multiline
                rows={3}
                value={formData.notes}
                onChange={(e) => handleInputChange('notes', e.target.value)}
                placeholder="Add any notes about this book..."
                disabled={loading}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button 
            type="submit" 
            variant="contained" 
            disabled={loading}
          >
            {loading ? 'Creating...' : 'Create Book'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};

export default CreateBookModal; 