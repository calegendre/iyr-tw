import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Register = () => {
  const [formData, setFormData] = useState({
    email: '',
    username: '',
    password: '',
    passwordConfirm: '',
    fullName: ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { register } = useAuth();
  const navigate = useNavigate();
  
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    
    // Validate passwords match
    if (formData.password !== formData.passwordConfirm) {
      setError('Passwords do not match');
      return;
    }
    
    setIsLoading(true);
    
    try {
      const success = await register({
        email: formData.email,
        username: formData.username,
        password: formData.password,
        full_name: formData.fullName,
        role: 'member' // Default role for new registrations
      });
      
      if (success) {
        navigate('/');
      } else {
        setError('Registration failed. Please try again.');
      }
    } catch (err) {
      setError(err.message || 'An error occurred during registration.');
    } finally {
      setIsLoading(false);
    }
  };
  
  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-md mx-auto bg-gray-800 rounded-lg p-8 shadow-lg">
          <h1 className="text-3xl font-bold mb-6 text-center">Create an Account</h1>
          
          {error && (
            <div className="bg-red-500/20 border border-red-500 text-red-100 px-4 py-3 rounded mb-4">
              {error}
            </div>
          )}
          
          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label htmlFor="email" className="block text-sm font-medium mb-1">
                Email
              </label>
              <input
                id="email"
                name="email"
                type="email"
                value={formData.email}
                onChange={handleChange}
                required
                className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="your@email.com"
              />
            </div>
            
            <div className="mb-4">
              <label htmlFor="username" className="block text-sm font-medium mb-1">
                Username
              </label>
              <input
                id="username"
                name="username"
                type="text"
                value={formData.username}
                onChange={handleChange}
                required
                className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="CoolDJ123"
              />
            </div>
            
            <div className="mb-4">
              <label htmlFor="fullName" className="block text-sm font-medium mb-1">
                Full Name
              </label>
              <input
                id="fullName"
                name="fullName"
                type="text"
                value={formData.fullName}
                onChange={handleChange}
                className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="John Doe"
              />
              <p className="text-xs text-gray-400 mt-1">Optional</p>
            </div>
            
            <div className="mb-4">
              <label htmlFor="password" className="block text-sm font-medium mb-1">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                value={formData.password}
                onChange={handleChange}
                required
                className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="••••••••"
              />
            </div>
            
            <div className="mb-6">
              <label htmlFor="passwordConfirm" className="block text-sm font-medium mb-1">
                Confirm Password
              </label>
              <input
                id="passwordConfirm"
                name="passwordConfirm"
                type="password"
                value={formData.passwordConfirm}
                onChange={handleChange}
                required
                className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="••••••••"
              />
            </div>
            
            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors disabled:bg-purple-400 disabled:cursor-not-allowed"
            >
              {isLoading ? 'Creating account...' : 'Sign Up'}
            </button>
          </form>
          
          <div className="mt-6 text-center">
            <p className="text-gray-400">
              Already have an account?{' '}
              <Link to="/login" className="text-purple-400 hover:text-purple-300">
                Login
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register;
