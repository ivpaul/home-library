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
} from '@mui/material';
import { useAuth } from '../contexts/AuthContext';

const LoginModal = ({ open, onClose }) => {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [error, setError] = useState('');
  const [isChangingPassword, setIsChangingPassword] = useState(false);
  const { signIn, completePasswordChange, loading } = useAuth();

  const handleInputChange = (field) => (e) => {
    setFormData(prev => ({ ...prev, [field]: e.target.value }));
  };

  const resetForm = () => {
    setFormData({
      email: '',
      password: '',
      newPassword: '',
      confirmPassword: ''
    });
    setError('');
    setIsChangingPassword(false);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (isChangingPassword) {
      // Handle password change
      if (formData.newPassword !== formData.confirmPassword) {
        setError('New passwords do not match');
        return;
      }
      
      if (formData.newPassword.length < 8) {
        setError('New password must be at least 8 characters long');
        return;
      }

      const result = await completePasswordChange(formData.newPassword);
      
      if (result.success) {
        onClose();
        resetForm();
      } else {
        setError(result.error);
      }
    } else {
      // Handle initial login
      const result = await signIn(formData.email, formData.password);
      
      if (result.success) {
        onClose();
        resetForm();
      } else if (result.requiresPasswordChange) {
        setIsChangingPassword(true);
        setError('');
      } else {
        setError(result.error);
      }
    }
  };

  const handleClose = () => {
    onClose();
    resetForm();
  };

  const renderLoginForm = () => (
    <>
      <TextField
        fullWidth
        label="Email"
        type="email"
        value={formData.email}
        onChange={handleInputChange('email')}
        margin="normal"
        required
        autoFocus
        disabled={loading}
      />
      
      <TextField
        fullWidth
        label="Password"
        type="password"
        value={formData.password}
        onChange={handleInputChange('password')}
        margin="normal"
        required
        disabled={loading}
      />
    </>
  );

  const renderPasswordChangeForm = () => (
    <>
      <TextField
        fullWidth
        label="New Password"
        type="password"
        value={formData.newPassword}
        onChange={handleInputChange('newPassword')}
        margin="normal"
        required
        autoFocus
        disabled={loading}
        helperText="Password must be at least 8 characters long"
      />
      
      <TextField
        fullWidth
        label="Confirm New Password"
        type="password"
        value={formData.confirmPassword}
        onChange={handleInputChange('confirmPassword')}
        margin="normal"
        required
        disabled={loading}
      />
    </>
  );

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        {isChangingPassword ? 'Change Password' : 'Admin Login'}
      </DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            {isChangingPassword 
              ? 'Please set a new password for your account'
              : 'Sign in to access admin features'
            }
          </Typography>
          
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          {isChangingPassword ? renderPasswordChangeForm() : renderLoginForm()}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} disabled={loading}>
            Cancel
          </Button>
          <Button 
            type="submit" 
            variant="contained" 
            disabled={loading}
          >
            {loading 
              ? (isChangingPassword ? 'Changing Password...' : 'Signing In...') 
              : (isChangingPassword ? 'Change Password' : 'Sign In')
            }
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};

export default LoginModal; 