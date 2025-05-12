import React, { createContext, useState, useContext, useEffect } from 'react';
import axios from 'axios';

// Get the backend URL from environment variable
const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

// Create the auth context
const AuthContext = createContext();

// Custom hook to use the auth context
export const useAuth = () => useContext(AuthContext);

// Provider component
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Check if user is logged in on initial load
  useEffect(() => {
    const checkUser = async () => {
      if (token) {
        try {
          // For development, we'll use a mock user instead of API call
          const mockUser = JSON.parse(localStorage.getItem('user')) || {
            id: 'mock-id',
            email: 'user@example.com',
            username: 'testuser',
            full_name: 'Test User',
            role: localStorage.getItem('mockRole') || 'member',
            profile_image_url: null,
            bio: 'This is a test user profile.',
            created_at: new Date().toISOString()
          };
          
          setUser(mockUser);
          
          // In a real app, we would make an API call
          // Add the token to all future requests
          axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
        } catch (err) {
          // If the token is invalid, clear it
          console.error('Error fetching user data:', err);
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          setToken(null);
          setUser(null);
        }
      }
      setLoading(false);
    };
    
    checkUser();
  }, [token]);
  
  // Login function
  const login = async (email, password) => {
    try {
      setError('');
      
      // For development, we'll use mock auth
      const mockUser = {
        id: 'mock-id',
        email: email,
        username: email.split('@')[0],
        full_name: 'Test User',
        role: 'member', // Default to member
        profile_image_url: null,
        bio: 'This is a test user profile.',
        created_at: new Date().toISOString()
      };
      
      // Check if this is a special test account
      if (email === 'admin@test.com') {
        mockUser.role = 'admin';
      } else if (email === 'staff@test.com') {
        mockUser.role = 'staff';
      } else if (email === 'artist@test.com') {
        mockUser.role = 'artist';
      } else if (email === 'podcaster@test.com') {
        mockUser.role = 'podcaster';
      }
      
      // Save mock token and user
      const mockToken = 'mock-token-' + Date.now();
      localStorage.setItem('token', mockToken);
      localStorage.setItem('user', JSON.stringify(mockUser));
      localStorage.setItem('mockRole', mockUser.role);
      
      setToken(mockToken);
      setUser(mockUser);
      
      return true;
      
      // In a real app, we would make an API call:
      /*
      const response = await axios.post(`${API}/auth/login`, { email, password });
      
      // Save the token to local storage and state
      const newToken = response.data.access_token;
      localStorage.setItem('token', newToken);
      setToken(newToken);
      
      // Set the token for future requests
      axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`;
      
      // Get the user data
      const userResponse = await axios.get(`${API}/users/me`);
      setUser(userResponse.data);
      */
      
    } catch (err) {
      setError(err.response?.data?.detail || 'Login failed. Please check your credentials.');
      return false;
    }
  };
  
  // Register function
  const register = async (userData) => {
    try {
      setError('');
      
      // For development, we'll use mock auth
      const mockUser = {
        id: 'mock-id',
        email: userData.email,
        username: userData.username,
        full_name: userData.full_name || '',
        role: userData.role || 'member',
        profile_image_url: null,
        bio: '',
        created_at: new Date().toISOString()
      };
      
      // Save mock token and user
      const mockToken = 'mock-token-' + Date.now();
      localStorage.setItem('token', mockToken);
      localStorage.setItem('user', JSON.stringify(mockUser));
      localStorage.setItem('mockRole', mockUser.role);
      
      setToken(mockToken);
      setUser(mockUser);
      
      return true;
      
      // In a real app, we would make an API call:
      /*
      await axios.post(`${API}/auth/register`, userData);
      
      // Automatically log in after registration
      return await login(userData.email, userData.password);
      */
      
    } catch (err) {
      setError(err.response?.data?.detail || 'Registration failed. Please try again.');
      return false;
    }
  };
  
  // Logout function
  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('mockRole');
    setToken(null);
    setUser(null);
    delete axios.defaults.headers.common['Authorization'];
  };
  
  // Value to be provided by the context
  const value = {
    user,
    token,
    loading,
    error,
    login,
    register,
    logout
  };
  
  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
