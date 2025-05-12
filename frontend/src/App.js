import { useEffect, useState, createContext, useRef } from "react";
import "./App.css";
import { BrowserRouter, Routes, Route, Link, Navigate } from "react-router-dom";
import axios from "axios";
import MediaPlayer from "./components/MediaPlayer";
import {
  mockArtists,
  mockTracks,
  mockAlbums,
  mockPodcasts,
  mockBlogPosts
} from "./mockData";

// Context for authentication
export const AuthContext = createContext();

// Backend URL from environment variables
const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

// Audio player context
export const AudioPlayerContext = createContext();

// Layout component with persistent audio player
const Layout = ({ children }) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTrack, setCurrentTrack] = useState(null);
  const [volume, setVolume] = useState(80);
  const audioRef = useRef(null);

  const playTrack = (track) => {
    setCurrentTrack(track);
    setIsPlaying(true);
  };

  const pauseTrack = () => {
    setIsPlaying(false);
  };

  const resumeTrack = () => {
    setIsPlaying(true);
  };

  const setAudioVolume = (newVolume) => {
    setVolume(newVolume);
    if (audioRef.current) {
      audioRef.current.volume = newVolume / 100;
    }
  };

  return (
    <AudioPlayerContext.Provider
      value={{
        isPlaying,
        currentTrack,
        volume,
        audioRef,
        playTrack,
        pauseTrack,
        resumeTrack,
        setAudioVolume,
      }}
    >
      <div className="flex flex-col min-h-screen">
        <header className="bg-gray-900 text-white">
          <div className="container mx-auto flex justify-between items-center p-4">
            <div className="flex items-center">
              <Link to="/" className="text-2xl font-bold">
                itsyourradio
              </Link>
            </div>
            <nav>
              <ul className="flex space-x-4">
                <li>
                  <Link to="/" className="hover:text-gray-300">
                    Home
                  </Link>
                </li>
                <li>
                  <Link to="/artists" className="hover:text-gray-300">
                    Artists
                  </Link>
                </li>
                <li>
                  <Link to="/podcasts" className="hover:text-gray-300">
                    Podcasts
                  </Link>
                </li>
                <li>
                  <Link to="/blog" className="hover:text-gray-300">
                    Blog
                  </Link>
                </li>
              </ul>
            </nav>
          </div>
        </header>

        <main className="flex-grow">
          {children}
        </main>

        {/* Persistent Audio Player */}
        <MediaPlayer />

        <footer className="bg-gray-900 text-white py-8">
          <div className="container mx-auto">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div>
                <h3 className="text-lg font-semibold mb-4">About Us</h3>
                <p className="text-gray-400">
                  itsyourradio is a platform for artists and podcasters to share their content with the world.
                </p>
              </div>
              <div>
                <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
                <ul className="space-y-2 text-gray-400">
                  <li>
                    <Link to="/about" className="hover:text-white">
                      About
                    </Link>
                  </li>
                  <li>
                    <Link to="/contact" className="hover:text-white">
                      Contact
                    </Link>
                  </li>
                  <li>
                    <Link to="/privacy" className="hover:text-white">
                      Privacy Policy
                    </Link>
                  </li>
                  <li>
                    <Link to="/terms" className="hover:text-white">
                      Terms of Service
                    </Link>
                  </li>
                </ul>
              </div>
              <div>
                <h3 className="text-lg font-semibold mb-4">Connect With Us</h3>
                <div className="flex space-x-4">
                  <a href="#" className="text-gray-400 hover:text-white">
                    Facebook
                  </a>
                  <a href="#" className="text-gray-400 hover:text-white">
                    Twitter
                  </a>
                  <a href="#" className="text-gray-400 hover:text-white">
                    Instagram
                  </a>
                </div>
              </div>
            </div>
            <div className="mt-8 pt-8 border-t border-gray-800 text-center text-gray-400">
              <p>&copy; {new Date().getFullYear()} itsyourradio. All rights reserved.</p>
            </div>
          </div>
        </footer>
      </div>
    </AudioPlayerContext.Provider>
  );
};

// Home page component
const Home = () => {
  const [message, setMessage] = useState("");

  const fetchData = async () => {
    try {
      const response = await axios.get(`${API}/`);
      setMessage(response.data.message);
    } catch (e) {
      console.error(e, `Error fetching data from API`);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  return (
    <div className="container mx-auto px-4 py-8">
      <section className="mb-12">
        <div className="bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg p-8 shadow-xl">
          <h1 className="text-4xl font-bold mb-4">Welcome to itsyourradio</h1>
          <p className="text-xl mb-6">Your place for the best music and podcasts.</p>
          <p>API Message: {message}</p>
          <div className="flex space-x-4">
            <Link
              to="/artists"
              className="bg-white text-purple-600 px-6 py-2 rounded-full font-semibold hover:bg-gray-100 transition-colors"
            >
              Explore Artists
            </Link>
            <Link
              to="/podcasts"
              className="bg-transparent border border-white text-white px-6 py-2 rounded-full font-semibold hover:bg-white hover:text-purple-600 transition-colors"
            >
              Discover Podcasts
            </Link>
          </div>
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-3xl font-bold mb-6">Featured Artists</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {/* Artist cards will go here */}
          <div className="bg-white p-4 rounded-lg shadow-md">
            <div className="h-48 bg-gray-200 rounded-md mb-4"></div>
            <h3 className="text-xl font-semibold">Artist Name</h3>
            <p className="text-gray-600">Genre</p>
          </div>
          {/* Repeat for other featured artists */}
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-3xl font-bold mb-6">Latest Podcasts</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Podcast cards will go here */}
          <div className="bg-white p-4 rounded-lg shadow-md">
            <div className="h-48 bg-gray-200 rounded-md mb-4"></div>
            <h3 className="text-xl font-semibold">Podcast Title</h3>
            <p className="text-gray-600">Host Name</p>
            <p className="text-gray-500 text-sm mt-2">Latest Episode: Episode Title</p>
          </div>
          {/* Repeat for other latest podcasts */}
        </div>
      </section>

      <section>
        <h2 className="text-3xl font-bold mb-6">Recent Blog Posts</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Blog post cards will go here */}
          <div className="bg-white p-4 rounded-lg shadow-md">
            <div className="h-48 bg-gray-200 rounded-md mb-4"></div>
            <h3 className="text-xl font-semibold">Blog Post Title</h3>
            <p className="text-gray-600">Author Name</p>
            <p className="text-gray-500 text-sm mt-2">Published: Date</p>
            <p className="mt-2">Lorem ipsum dolor sit amet, consectetur adipiscing elit...</p>
          </div>
          {/* Repeat for other recent blog posts */}
        </div>
      </section>
    </div>
  );
};

// Artists page (placeholder)
const Artists = () => {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Artists</h1>
      <p>This page will list all artists.</p>
    </div>
  );
};

// Podcasts page (placeholder)
const Podcasts = () => {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Podcasts</h1>
      <p>This page will list all podcasts.</p>
    </div>
  );
};

// Blog page (placeholder)
const Blog = () => {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Blog</h1>
      <p>This page will list all blog posts.</p>
    </div>
  );
};

// Main App component
function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Check if user is authenticated on app load
  useEffect(() => {
    const token = localStorage.getItem("token");
    if (token) {
      // Verify token validity with backend
      const verifyToken = async () => {
        try {
          const response = await axios.get(`${API}/auth/me`, {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          });
          setUser(response.data);
          setIsAuthenticated(true);
        } catch (error) {
          console.error("Token verification failed:", error);
          localStorage.removeItem("token");
        } finally {
          setLoading(false);
        }
      };
      verifyToken();
    } else {
      setLoading(false);
    }
  }, []);

  // Login function
  const login = async (email, password) => {
    try {
      const response = await axios.post(`${API}/auth/token`, {
        username: email,
        password: password,
      });
      const { access_token } = response.data;
      localStorage.setItem("token", access_token);
      
      // Get user data
      const userResponse = await axios.get(`${API}/auth/me`, {
        headers: {
          Authorization: `Bearer ${access_token}`,
        },
      });
      setUser(userResponse.data);
      setIsAuthenticated(true);
      return true;
    } catch (error) {
      console.error("Login failed:", error);
      return false;
    }
  };

  // Logout function
  const logout = () => {
    localStorage.removeItem("token");
    setUser(null);
    setIsAuthenticated(false);
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated, user, login, logout }}>
      <div className="App">
        <BrowserRouter>
          <Layout>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/artists" element={<Artists />} />
              <Route path="/podcasts" element={<Podcasts />} />
              <Route path="/blog" element={<Blog />} />
              {/* Add more routes as needed */}
            </Routes>
          </Layout>
        </BrowserRouter>
      </div>
    </AuthContext.Provider>
  );
}

export default App;
