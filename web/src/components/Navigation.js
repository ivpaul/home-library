import React, { useState } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Box,
  Button,
  Chip,
  useTheme,
} from '@mui/material';
import { useAuth } from '../contexts/AuthContext';
import LoginModal from './LoginModal';

const Navigation = () => {
  const theme = useTheme();
  const { user, signOut } = useAuth();
  const [loginModalOpen, setLoginModalOpen] = useState(false);

  return (
    <>
      <AppBar position="fixed" sx={{ zIndex: theme.zIndex.drawer + 1 }}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            🌟 Annie's Fan Club
          </Typography>
          
          {user ? (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Chip 
                label={`Admin: ${user.email}`} 
                color="secondary" 
                size="small"
              />
              <Button 
                color="inherit" 
                onClick={signOut}
                variant="outlined"
                size="small"
              >
                Sign Out
              </Button>
            </Box>
          ) : (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Typography variant="body2" color="inherit">
                Public Access
              </Typography>
              <Button 
                color="inherit" 
                onClick={() => setLoginModalOpen(true)}
                variant="outlined"
                size="small"
              >
                Admin Login
              </Button>
            </Box>
          )}
        </Toolbar>
      </AppBar>
      
      <LoginModal 
        open={loginModalOpen} 
        onClose={() => setLoginModalOpen(false)} 
      />
    </>
  );
};

export default Navigation; 