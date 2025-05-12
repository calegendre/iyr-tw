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
          // Add the token to all future requests
          axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
          
          // Get user information
          const response = await axios.get(`${API}/users/me`);
          setUser(response.data);
        } catch (err) {
          // If the token is invalid, clear it
          console.error('Error fetching user data:', err);
          localStorage.removeItem('token');
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
      
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Login failed. Please check your credentials.');
      return false;
    }
  };
  
  // Register function
  const register = async (userData) => {
    try {
      setError('');
      await axios.post(`${API}/auth/register`, userData);
      
      // Automatically log in after registration
      return await login(userData.email, userData.password);
    } catch (err) {
      setError(err.response?.data?.detail || 'Registration failed. Please try again.');
      return false;
    }
  };
  
  // Logout function
  const logout = () => {
    localStorage.removeItem('token');
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
