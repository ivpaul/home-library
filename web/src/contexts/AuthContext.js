import React, { createContext, useContext, useState, useEffect } from 'react';
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// Cognito configuration
const poolData = {
  UserPoolId: process.env.REACT_APP_COGNITO_USER_POOL_ID,
  ClientId: process.env.REACT_APP_COGNITO_CLIENT_ID
};

export const userPool = new CognitoUserPool(poolData);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [requiresPasswordChange, setRequiresPasswordChange] = useState(false);
  const [pendingCognitoUser, setPendingCognitoUser] = useState(null);
  const [pendingRequiredAttributes, setPendingRequiredAttributes] = useState(null);

  // Check if user is already authenticated
  useEffect(() => {
    checkAuthState();
  }, []);

  const checkAuthState = () => {
    const currentUser = userPool.getCurrentUser();
    if (currentUser) {
      currentUser.getSession((err, session) => {
        if (err) {
          console.error('Error getting session:', err);
          setUser(null);
        } else if (session.isValid()) {
          // Get user attributes
          currentUser.getUserAttributes((err, attributes) => {
            if (err) {
              console.error('Error getting user attributes:', err);
              setUser(null);
            } else {
              const userData = {
                username: currentUser.getUsername(),
                email: attributes.find(attr => attr.Name === 'email')?.Value
              };
              setUser(userData);
            }
          });
        } else {
          setUser(null);
        }
        setLoading(false);
      });
    } else {
      setLoading(false);
    }
  };

  const signIn = async (email, password) => {
    return new Promise((resolve) => {
      // Use email directly as username
      const username = email;

      const authenticationDetails = new AuthenticationDetails({
        Username: username,
        Password: password,
      });

      const cognitoUser = new CognitoUser({
        Username: username,
        Pool: userPool
      });

      cognitoUser.authenticateUser(authenticationDetails, {
        onSuccess: (result) => {
          setRequiresPasswordChange(false);
          setPendingCognitoUser(null);
          setPendingRequiredAttributes(null);
          checkAuthState();
          resolve({ success: true });
        },
        onFailure: (err) => {
          console.error('Authentication failed:', err);
          resolve({ success: false, error: err.message });
        },
        newPasswordRequired: (userAttributes, requiredAttributes) => {
          setRequiresPasswordChange(true);
          setPendingCognitoUser(cognitoUser);
          setPendingRequiredAttributes(requiredAttributes);
          resolve({ success: false, requiresPasswordChange: true });
        }
      });
    });
  };

  const completePasswordChange = async (newPassword) => {
    return new Promise((resolve) => {
      if (!pendingCognitoUser || !pendingRequiredAttributes) {
        resolve({ success: false, error: 'No pending password change' });
        return;
      }

      pendingCognitoUser.completeNewPasswordChallenge(newPassword, pendingRequiredAttributes, {
        onSuccess: (result) => {
          setRequiresPasswordChange(false);
          setPendingCognitoUser(null);
          setPendingRequiredAttributes(null);
          checkAuthState();
          resolve({ success: true });
        },
        onFailure: (err) => {
          console.error('Password change failed:', err);
          resolve({ success: false, error: 'Password change failed: ' + err.message });
        }
      });
    });
  };

  const signOut = () => {
    const currentUser = userPool.getCurrentUser();
    if (currentUser) {
      currentUser.signOut();
    }
    setUser(null);
    setRequiresPasswordChange(false);
    setPendingCognitoUser(null);
    setPendingRequiredAttributes(null);
  };

  const value = {
    user,
    loading,
    signIn,
    signOut,
    requiresPasswordChange,
    completePasswordChange,
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}; 