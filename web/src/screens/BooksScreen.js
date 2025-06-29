import React, { useState, useEffect } from 'react';
import {
  Container,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Box,
  CircularProgress,
  Alert,
  IconButton,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  CheckCircle as CheckInIcon,
  Cancel as CheckOutIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import apiService from '../services/api';
import toast from 'react-hot-toast';
import { useAuth } from '../contexts/AuthContext';
import CreateBookModal from '../components/CreateBookModal';

const BooksScreen = () => {
  const [books, setBooks] = useState([]);
  const [filteredBooks, setFilteredBooks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBook, setSelectedBook] = useState(null);
  const [showNotesDialog, setShowNotesDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showCreateBookModal, setShowCreateBookModal] = useState(false);
  const [notesText, setNotesText] = useState('');

  const { user } = useAuth();

  // Check if user is admin (logged in)
  const isAdmin = !!user;

  useEffect(() => {
    fetchBooks();
  }, []);

  useEffect(() => {
    filterBooks();
  }, [searchQuery, books]);

  const fetchBooks = async () => {
    try {
      setLoading(true);
      const response = await apiService.getBooks();
      // Handle both array and object with books property
      const booksData = Array.isArray(response) ? response : (response.books || []);
      setBooks(booksData);
    } catch (error) {
      console.error('Error loading books:', error);
      toast.error('Failed to load books');
    } finally {
      setLoading(false);
    }
  };

  const filterBooks = () => {
    if (!searchQuery.trim()) {
      setFilteredBooks(books);
      return;
    }

    const filtered = books.filter(book =>
      book.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      book.authors?.toLowerCase().includes(searchQuery.toLowerCase())
    );
    setFilteredBooks(filtered);
  };

  const handleSearch = (event) => {
    setSearchQuery(event.target.value);
  };

  const handleEditNotes = (book) => {
    setSelectedBook(book);
    setNotesText(book.notes || '');
    setShowNotesDialog(true);
  };

  const handleEdit = (book) => {
    handleEditNotes(book);
  };

  const handleSaveNotes = async () => {
    try {
      await apiService.updateBook(selectedBook.isbn, { notes: notesText });
      await fetchBooks();
      setShowNotesDialog(false);
      setSelectedBook(null);
      setNotesText('');
      toast.success('Notes updated successfully');
    } catch (error) {
      console.error('Error saving notes:', error);
      toast.error('Failed to save notes');
    }
  };

  const handleCheckInOut = async (book) => {
    try {
      const result = await apiService.toggleBookAvailability(book);
      if (result.success) {
        await fetchBooks();
        toast.success(`Book ${result.action} successfully`);
      } else {
        toast.error(result.error);
      }
    } catch (error) {
      console.error('Error updating book status:', error);
      toast.error('Failed to update book status');
    }
  };

  const handleDeleteBook = (book) => {
    setSelectedBook(book);
    setShowDeleteDialog(true);
  };

  const confirmDelete = async () => {
    try {
      await apiService.deleteBook(selectedBook.isbn);
      await fetchBooks();
      setShowDeleteDialog(false);
      setSelectedBook(null);
      toast.success('Book deleted successfully');
    } catch (error) {
      console.error('Error deleting book:', error);
      toast.error('Failed to delete book');
    }
  };

  const getStatusColor = (book) => {
    const isAvailable = apiService.isBookAvailable(book);
    return isAvailable ? 'success' : 'warning';
  };

  const getStatusLabel = (book) => {
    const isAvailable = apiService.isBookAvailable(book);
    return isAvailable ? 'Available' : 'Borrowed';
  };

  if (loading) {
    return (
      <Container sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
        <CircularProgress />
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Home Library
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
          Browse and manage your book collection
        </Typography>
        
        <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
          <TextField
            placeholder="Search books..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
            }}
            sx={{ minWidth: 300, flexGrow: 1 }}
          />
          {isAdmin && (
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => setShowCreateBookModal(true)}
              sx={{ minWidth: 140 }}
            >
              Add Book
            </Button>
          )}
        </Box>
      </Box>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : filteredBooks.length === 0 ? (
        <Alert severity="info">
          {searchQuery ? 'No books found matching your search.' : 'No books in your library yet.'}
        </Alert>
      ) : (
        <Grid container spacing={3}>
          {filteredBooks.map((book) => (
            <Grid item xs={12} sm={6} md={4} key={book.id}>
              <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                <CardContent sx={{ flexGrow: 1 }}>
                  <Typography variant="h6" component="h2" gutterBottom>
                    {book.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    by {book.authors || book.author}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    ISBN: {book.isbn}
                  </Typography>
                  {book.publication_date && (
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Published: {new Date(book.publication_date).getFullYear()}
                    </Typography>
                  )}
                  {book.pages && (
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      {book.pages} pages
                    </Typography>
                  )}
                  <Box sx={{ mt: 2, mb: 2 }}>
                    <Chip
                      label={book.status === 'available' ? 'Available' : 'Checked Out'}
                      color={book.status === 'available' ? 'success' : 'warning'}
                      size="small"
                    />
                  </Box>
                  {book.notes && (
                    <Button
                      size="small"
                      onClick={() => {
                        setSelectedBook(book);
                        setNotesText(book.notes);
                        setShowNotesDialog(true);
                      }}
                    >
                      View Notes
                    </Button>
                  )}
                </CardContent>
                {isAdmin && (
                  <Box sx={{ p: 2, pt: 0 }}>
                    <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                      <IconButton
                        size="small"
                        onClick={() => handleCheckInOut(book)}
                        color={book.status === 'available' ? 'warning' : 'success'}
                      >
                        {book.status === 'available' ? <CheckOutIcon /> : <CheckInIcon />}
                      </IconButton>
                      <IconButton
                        size="small"
                        onClick={() => handleEdit(book)}
                        color="primary"
                      >
                        <EditIcon />
                      </IconButton>
                      <IconButton
                        size="small"
                        onClick={() => {
                          setSelectedBook(book);
                          setShowDeleteDialog(true);
                        }}
                        color="error"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  </Box>
                )}
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Notes Dialog */}
      <Dialog open={showNotesDialog} onClose={() => setShowNotesDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Notes for "{selectedBook?.title}"</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            multiline
            rows={4}
            variant="outlined"
            placeholder="Add your notes about this book..."
            value={notesText}
            onChange={(e) => setNotesText(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowNotesDialog(false)}>
            Cancel
          </Button>
          <Button onClick={handleSaveNotes} variant="contained" color="primary">
            Save Notes
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={showDeleteDialog} onClose={() => setShowDeleteDialog(false)}>
        <DialogTitle>Delete Book</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete "{selectedBook?.title}"? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowDeleteDialog(false)}>Cancel</Button>
          <Button onClick={confirmDelete} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>

      {/* Create Book Modal */}
      <CreateBookModal
        open={showCreateBookModal}
        onClose={() => setShowCreateBookModal(false)}
        onBookCreated={fetchBooks}
      />
    </Container>
  );
};

export default BooksScreen; 