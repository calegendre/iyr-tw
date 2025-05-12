import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const Header = () => {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const { user, logout } = useAuth();
  const location = useLocation();

  // Handle scroll event to shrink header
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 50) {
        setScrolled(true);
      } else {
        setScrolled(false);
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu when route changes
  useEffect(() => {
    setMobileMenuOpen(false);
  }, [location]);

  return (
    <header 
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled ? 'bg-black/90 py-2' : 'bg-black py-4'
      }`}
    >
      <div className="container mx-auto px-4 flex justify-between items-center">
        {/* Logo */}
        <Link to="/" className="flex items-center">
          <img 
            src="/logo.png" 
            alt="ItsYourRadio" 
            className={`transition-all duration-300 ${
              scrolled ? 'h-10' : 'h-14'
            }`}
          />
          <span className={`ml-2 text-white font-bold transition-all duration-300 ${
            scrolled ? 'text-xl' : 'text-2xl'
          }`}>
            ItsYourRadio
          </span>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:block">
          <ul className="flex space-x-6">
            <li>
              <Link to="/" className="text-white hover:text-purple-400 transition">Home</Link>
            </li>
            <li>
              <Link to="/artists" className="text-white hover:text-purple-400 transition">Artists</Link>
            </li>
            <li>
              <Link to="/podcasts" className="text-white hover:text-purple-400 transition">Podcasts</Link>
            </li>
            <li>
              <Link to="/blog" className="text-white hover:text-purple-400 transition">Blog</Link>
            </li>
            {user ? (
              <>
                <li>
                  <Link to="/profile" className="text-white hover:text-purple-400 transition">Profile</Link>
                </li>
                {(user.role === 'admin' || user.role === 'staff') && (
                  <li>
                    <Link to="/admin" className="text-white hover:text-purple-400 transition">Admin</Link>
                  </li>
                )}
                {(user.role === 'artist') && (
                  <li>
                    <Link to="/artist-dashboard" className="text-white hover:text-purple-400 transition">Artist Dashboard</Link>
                  </li>
                )}
                {(user.role === 'podcaster') && (
                  <li>
                    <Link to="/podcaster-dashboard" className="text-white hover:text-purple-400 transition">Podcaster Dashboard</Link>
                  </li>
                )}
                <li>
                  <button 
                    onClick={logout} 
                    className="text-white hover:text-purple-400 transition"
                  >
                    Logout
                  </button>
                </li>
              </>
            ) : (
              <>
                <li>
                  <Link to="/login" className="text-white hover:text-purple-400 transition">Login</Link>
                </li>
                <li>
                  <Link to="/register" className="text-white hover:text-purple-400 transition bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded-md">Sign Up</Link>
                </li>
              </>
            )}
          </ul>
        </nav>

        {/* Mobile Menu Button */}
        <button 
          className="md:hidden text-white p-2 rounded-md hover:bg-gray-800"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          aria-label="Toggle mobile menu"
        >
          {mobileMenuOpen ? (
            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          ) : (
            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16m-7 6h7" />
            </svg>
          )}
        </button>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-black/95 border-t border-gray-800 absolute top-full left-0 right-0 shadow-lg z-20">
          <ul className="py-2 px-4 space-y-2">
            <li>
              <Link to="/" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Home</Link>
            </li>
            <li>
              <Link to="/artists" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Artists</Link>
            </li>
            <li>
              <Link to="/podcasts" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Podcasts</Link>
            </li>
            <li>
              <Link to="/blog" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Blog</Link>
            </li>
            {user ? (
              <>
                <li>
                  <Link to="/profile" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Profile</Link>
                </li>
                {(user.role === 'admin' || user.role === 'staff') && (
                  <li>
                    <Link to="/admin" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Admin</Link>
                  </li>
                )}
                {(user.role === 'artist') && (
                  <li>
                    <Link to="/artist-dashboard" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Artist Dashboard</Link>
                  </li>
                )}
                {(user.role === 'podcaster') && (
                  <li>
                    <Link to="/podcaster-dashboard" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Podcaster Dashboard</Link>
                  </li>
                )}
                <li>
                  <button 
                    onClick={logout} 
                    className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md w-full text-left"
                  >
                    Logout
                  </button>
                </li>
              </>
            ) : (
              <>
                <li>
                  <Link to="/login" className="block text-white py-3 px-2 hover:bg-gray-800 rounded-md">Login</Link>
                </li>
                <li>
                  <Link to="/register" className="block text-white py-3 px-2 bg-purple-600 hover:bg-purple-700 rounded-md my-2">Sign Up</Link>
                </li>
              </>
            )}
          </ul>
        </div>
      )}
    </header>
  );
};

export default Header;
