import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  Alert,
  Chip,
  Divider,
} from '@mui/material';
import { Star as StarIcon, Group as GroupIcon, Person as PersonIcon } from '@mui/icons-material';
import apiService from '../services/api';

const AdminFavorites = ({ adminFavoritesChanged }) => {
  const [admins, setAdmins] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchAdminFavorites();
  }, [adminFavoritesChanged]);

  const fetchAdminFavorites = async () => {
    try {
      setLoading(true);
      const data = await apiService.getAdminFavorites();
      setAdmins(data);
      setError(null);
    } catch (err) {
      console.error('Error fetching admin favorites:', err);
      setError('Failed to load admin favorite books');
      setAdmins([]);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 2 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  if (!admins || admins.length === 0) {
    return (
      <Box sx={{ mb: 4 }}>
        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          Our Favorite Books
        </Typography>
        <Alert severity="info">
          No favorite books have been selected by admins yet.
        </Alert>
      </Box>
    );
  }

  // Filter out admins with no favorites
  const adminsWithFavorites = admins
  .filter(admin => admin.favorites && admin.favorites.length > 0)
  .sort((a, b) => a.username.localeCompare(b.username));

  if (adminsWithFavorites.length === 0) {
    return (
      <Box sx={{ mb: 4 }}>
        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          Our Favorite Books
        </Typography>
        <Alert severity="info">
          No favorite books have been selected by admins yet.
        </Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ mb: 4 }}>
      <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        Our Favorite Books
      </Typography>
      
      {adminsWithFavorites.map((admin, adminIndex) => (
        <Box key={admin.username} sx={{ mb: 3 }}>
          <Typography 
            variant="subtitle1" 
            sx={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: 1, 
              mb: 2,
              fontWeight: 'bold',
              color: 'primary.main'
            }}
          >
            <PersonIcon />
            {admin.username}
          </Typography>
          
          <Box sx={{ 
            display: 'flex', 
            gap: 2, 
            overflowX: 'auto',
            pb: 1,
            '&::-webkit-scrollbar': {
              height: 8,
            },
            '&::-webkit-scrollbar-track': {
              backgroundColor: '#f1f1f1',
              borderRadius: 4,
            },
            '&::-webkit-scrollbar-thumb': {
              backgroundColor: '#888',
              borderRadius: 4,
            },
          }}>
            {admin.favorites.map((book, index) => (
              <Card 
                key={book.isbn || book.id || index} 
                sx={{ 
                  minWidth: 250, 
                  maxWidth: 300,
                  position: 'relative',
                  border: '2px solid',
                  borderColor: 'secondary.main',
                  borderRadius: 2,
                }}
              >
                <CardContent>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
                    <Chip 
                      label={`#${index + 1}`} 
                      color="secondary" 
                      size="small"
                      sx={{ fontWeight: 'bold' }}
                    />
                    <StarIcon color="secondary" />
                  </Box>
                  <Typography 
                    variant="subtitle1" 
                    gutterBottom 
                    sx={{ 
                      fontWeight: 'bold',
                      lineHeight: 1.2,
                      display: '-webkit-box',
                      WebkitLineClamp: 2,
                      WebkitBoxOrient: 'vertical',
                      overflow: 'hidden',
                    }}
                  >
                    {book.title}
                  </Typography>
                  <Typography 
                    variant="body2" 
                    color="text.secondary"
                    sx={{ 
                      mb: 1,
                      display: '-webkit-box',
                      WebkitLineClamp: 1,
                      WebkitBoxOrient: 'vertical',
                      overflow: 'hidden',
                    }}
                  >
                    by {book.authors || book.author}
                  </Typography>
                  <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                    <Chip 
                      label={book.status === 'available' ? 'Available' : 'Borrowed'} 
                      color={book.status === 'available' ? 'success' : 'warning'}
                      size="small"
                    />
                    {book.year && (
                      <Chip 
                        label={book.year} 
                        variant="outlined" 
                        size="small"
                      />
                    )}
                  </Box>
                </CardContent>
              </Card>
            ))}
          </Box>
          
          {adminIndex < adminsWithFavorites.length - 1 && (
            <Divider sx={{ mt: 2, mb: 2 }} />
          )}
        </Box>
      ))}
    </Box>
  );
};

export default AdminFavorites; 