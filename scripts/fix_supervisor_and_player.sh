#!/bin/bash

# Fix script for itsyourradio deployment
# Addresses supervisor permission issues and updates the MediaPlayer component

# Configuration
DOMAIN="itsyourradio.com"
WEB_ROOT="/home/radio/web/$DOMAIN"
PUBLIC_HTML="$WEB_ROOT/public_html"
BACKEND_DIR="$PUBLIC_HTML/backend"
VENV_DIR="$PUBLIC_HTML/venv"
LOGS_DIR="$WEB_ROOT/logs"
FRONTEND_SRC="$PUBLIC_HTML/frontend_src"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Function to check for errors and exit if any are found
check_error() {
    if [ $? -ne 0 ]; then
        log_error "$1"
        exit 1
    fi
}

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root"
    exit 1
fi

# 1. Fix supervisor permission issues
log_message "Fixing supervisor permission issues..."

# Make virtual environment binaries executable
chmod -R +x "$VENV_DIR/bin/"
check_error "Failed to make virtual environment binaries executable"

# Set correct ownership
chown -R radio:radio "$VENV_DIR"
check_error "Failed to set correct ownership for virtual environment"

# Update supervisor configuration
cat > /etc/supervisor/conf.d/itsyourradio.conf << EOL
[program:itsyourradio_backend]
command=$VENV_DIR/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8001
directory=$BACKEND_DIR
user=radio
group=radio
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=$LOGS_DIR/backend.log
environment=PATH="$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin",PYTHONPATH="$BACKEND_DIR"
EOL
check_error "Failed to update supervisor configuration"

# Reload supervisor
supervisorctl reread
supervisorctl update
supervisorctl restart itsyourradio_backend
check_error "Failed to restart itsyourradio_backend service"

log_message "✓ Supervisor issues fixed successfully"

# 2. Update the MediaPlayer component to support live streams
log_message "Updating MediaPlayer component..."

# Create the updated MediaPlayer component
cat > "$FRONTEND_SRC/src/components/MediaPlayer.js" << 'EOL'
import React, { useState, useEffect, useRef, useContext } from "react";
import { AudioPlayerContext } from "../App";

const MediaPlayer = () => {
  const {
    isPlaying,
    currentTrack,
    volume,
    audioRef,
    pauseTrack,
    resumeTrack,
    setAudioVolume,
    isLiveStream,
    toggleLiveStream,
    stopPlayback,
    streamUrl
  } = useContext(AudioPlayerContext);

  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const [dominantColor, setDominantColor] = useState("#4F46E5"); // Default color
  const progressRef = useRef(null);

  // Format time in MM:SS
  const formatTime = (seconds) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return `${minutes}:${remainingSeconds < 10 ? "0" : ""}${remainingSeconds}`;
  };

  // Extract dominant color from track cover image
  useEffect(() => {
    if (currentTrack?.coverImage && !isLiveStream) {
      // In a real app, you'd use a color extraction library
      // For now, we'll use a simple gradient based on a predefined color
      const getRandomColor = () => {
        const colors = ["#4F46E5", "#7C3AED", "#EC4899", "#EF4444", "#F59E0B", "#10B981"];
        return colors[Math.floor(Math.random() * colors.length)];
      };
      setDominantColor(getRandomColor());
    } else {
      // Default color for live stream
      setDominantColor("#4F46E5");
    }
  }, [currentTrack, isLiveStream]);

  // Set up audio element and listeners
  useEffect(() => {
    if (!audioRef.current) {
      audioRef.current = new Audio();
      audioRef.current.volume = volume / 100;
    }

    const setAudioData = () => {
      setDuration(audioRef.current.duration || 0);
    };

    const setAudioProgress = () => {
      if (isLiveStream) {
        // For live streams, we don't track progress
        setProgress(100);
        setCurrentTime(0);
      } else {
        setCurrentTime(audioRef.current.currentTime);
        if (audioRef.current.duration) {
          setProgress((audioRef.current.currentTime / audioRef.current.duration) * 100);
        }
      }
    };

    const onEnded = () => {
      if (!isLiveStream) {
        setProgress(0);
        setCurrentTime(0);
        pauseTrack();
      }
    };

    // Add event listeners
    audioRef.current.addEventListener("loadeddata", setAudioData);
    audioRef.current.addEventListener("timeupdate", setAudioProgress);
    audioRef.current.addEventListener("ended", onEnded);

    // Clean up
    return () => {
      audioRef.current.removeEventListener("loadeddata", setAudioData);
      audioRef.current.removeEventListener("timeupdate", setAudioProgress);
      audioRef.current.removeEventListener("ended", onEnded);
    };
  }, [audioRef, pauseTrack, volume, isLiveStream]);

  // Update when track or stream changes
  useEffect(() => {
    if (audioRef.current) {
      if (isLiveStream) {
        audioRef.current.src = streamUrl;
      } else if (currentTrack) {
        audioRef.current.src = currentTrack.audioUrl;
      }
      
      audioRef.current.load();
      if (isPlaying) {
        audioRef.current.play().catch(err => console.error("Playback failed:", err));
      }
    }
  }, [currentTrack, isLiveStream, streamUrl, isPlaying, audioRef]);

  // Handle play/pause
  useEffect(() => {
    if (audioRef.current) {
      if (isPlaying) {
        audioRef.current.play().catch(err => console.error("Playback failed:", err));
      } else {
        audioRef.current.pause();
      }
    }
  }, [isPlaying, audioRef]);

  // Handle volume change
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume / 100;
    }
  }, [volume, audioRef]);

  // Handle seeking
  const handleProgressChange = (e) => {
    if (isLiveStream) return; // Disable seeking for live streams
    
    const newProgress = e.target.value;
    setProgress(newProgress);
    if (audioRef.current && audioRef.current.duration) {
      audioRef.current.currentTime = (newProgress / 100) * audioRef.current.duration;
    }
  };

  // Determine if we should show the player
  const showPlayer = isLiveStream || currentTrack;
  
  if (!showPlayer) return null;

  // Generate gradient style based on dominant color
  const gradientStyle = {
    background: isPlaying 
      ? `linear-gradient(90deg, ${dominantColor} 0%, rgba(67, 56, 202, 0.8) 50%, ${dominantColor} 100%)`
      : 'rgb(31, 41, 55)', // Default dark background when not playing
    backgroundSize: '200% 100%',
    animation: isPlaying ? 'gradientAnimation 15s ease infinite' : 'none'
  };

  return (
    <div 
      className="fixed bottom-0 left-0 right-0 text-white p-3 z-50 transition-all" 
      style={gradientStyle}
    >
      <style>
        {`
        @keyframes gradientAnimation {
          0% { background-position: 0% 50%; }
          50% { background-position: 100% 50%; }
          100% { background-position: 0% 50%; }
        }
        `}
      </style>
      <div className="container mx-auto flex flex-col md:flex-row items-center justify-between px-4">
        <div className="flex items-center w-full md:w-auto mb-2 md:mb-0">
          {!isLiveStream && currentTrack?.coverImage ? (
            <img
              src={currentTrack.coverImage}
              alt={currentTrack.title}
              className="w-12 h-12 mr-4 rounded"
            />
          ) : (
            <div className="w-12 h-12 mr-4 rounded flex items-center justify-center bg-indigo-600">
              <span className="text-xl">📻</span>
            </div>
          )}
          <div className="truncate">
            <div className="font-semibold truncate">
              {isLiveStream ? "Live Radio Stream" : currentTrack?.title}
            </div>
            <div className="text-sm text-gray-200 truncate">
              {isLiveStream ? "itsyourradio" : currentTrack?.artist}
            </div>
          </div>
        </div>

        <div className="flex flex-col w-full md:w-1/2">
          <div className="flex items-center justify-center mb-1 space-x-4">
            <button
              onClick={isPlaying ? pauseTrack : resumeTrack}
              className="p-2 rounded-full bg-white text-gray-800 focus:outline-none hover:bg-gray-200"
              aria-label={isPlaying ? "Pause" : "Play"}
            >
              <span className="block w-5 h-5 flex items-center justify-center">
                {isPlaying ? "⏸" : "▶"}
              </span>
            </button>
            
            <button
              onClick={stopPlayback}
              className="p-2 rounded-full bg-white text-gray-800 focus:outline-none hover:bg-gray-200"
              aria-label="Stop"
            >
              <span className="block w-5 h-5 flex items-center justify-center">■</span>
            </button>
            
            <button
              onClick={toggleLiveStream}
              className={`p-2 rounded-full focus:outline-none ${
                isLiveStream 
                  ? "bg-green-500 text-white hover:bg-green-600" 
                  : "bg-white text-gray-800 hover:bg-gray-200"
              }`}
              aria-label="Live Stream"
            >
              <span className="block w-5 h-5 flex items-center justify-center">🔴</span>
            </button>
          </div>

          {!isLiveStream && (
            <div className="flex items-center space-x-2 w-full">
              <span className="text-xs">{formatTime(currentTime)}</span>
              <input
                ref={progressRef}
                type="range"
                className="range-input flex-grow"
                value={progress}
                onChange={handleProgressChange}
                min="0"
                max="100"
                step="0.1"
              />
              <span className="text-xs">{formatTime(duration)}</span>
            </div>
          )}
          
          {isLiveStream && (
            <div className="flex items-center justify-center w-full">
              <span className="text-sm animate-pulse">● Live</span>
            </div>
          )}
        </div>

        <div className="flex items-center mt-2 md:mt-0">
          <span className="mr-2 text-xs">
            {volume > 0 ? (
              <span className="block w-5 h-5 flex items-center justify-center">🔊</span>
            ) : (
              <span className="block w-5 h-5 flex items-center justify-center">🔇</span>
            )}
          </span>
          <input
            type="range"
            className="range-input w-20"
            value={volume}
            onChange={(e) => setAudioVolume(parseInt(e.target.value))}
            min="0"
            max="100"
            aria-label="Volume"
          />
        </div>
      </div>
    </div>
  );
};

export default MediaPlayer;
EOL
check_error "Failed to update MediaPlayer component"

# Update App.js to include live stream functionality
cat > "$FRONTEND_SRC/src/App.js" << 'EOL'
import { useEffect, useState, createContext, useRef, useContext } from "react";
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

// Radio stream URL - update this to your actual stream URL
const RADIO_STREAM_URL = "https://stream.itsyourradio.com/radio/8000/radio.mp3";

// Layout component with persistent audio player
const Layout = ({ children }) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTrack, setCurrentTrack] = useState(null);
  const [volume, setVolume] = useState(80);
  const [isLiveStream, setIsLiveStream] = useState(false);
  const audioRef = useRef(null);

  // Play a track
  const playTrack = (track) => {
    setIsLiveStream(false);
    setCurrentTrack(track);
    setIsPlaying(true);
  };

  // Pause playback
  const pauseTrack = () => {
    setIsPlaying(false);
  };

  // Resume playback
  const resumeTrack = () => {
    setIsPlaying(true);
  };

  // Toggle live stream
  const toggleLiveStream = () => {
    if (isLiveStream) {
      // Already in stream mode, just toggle play/pause
      setIsPlaying(!isPlaying);
    } else {
      // Switch to stream mode
      setCurrentTrack(null);
      setIsLiveStream(true);
      setIsPlaying(true);
    }
  };

  // Stop all playback
  const stopPlayback = () => {
    setIsPlaying(false);
    
    // If it's a regular track and we want to reset it
    if (!isLiveStream && audioRef.current) {
      audioRef.current.currentTime = 0;
    }
  };

  // Adjust volume
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
        isLiveStream,
        toggleLiveStream,
        stopPlayback,
        streamUrl: RADIO_STREAM_URL
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
                <li>
                  <button 
                    onClick={toggleLiveStream}
                    className={`hover:text-gray-300 flex items-center ${isLiveStream && isPlaying ? 'text-green-400' : ''}`}
                  >
                    <span className="mr-1">Live Radio</span>
                    {isLiveStream && isPlaying && <span className="animate-pulse">●</span>}
                  </button>
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
  const { playTrack, toggleLiveStream } = useContext(AudioPlayerContext);
  const [featuredArtists, setFeaturedArtists] = useState([]);
  const [latestPodcasts, setLatestPodcasts] = useState([]);
  const [recentPosts, setRecentPosts] = useState([]);

  const fetchData = async () => {
    try {
      const response = await axios.get(`${API}/`);
      setMessage(response.data.message);
      
      // In a real application, we would fetch this data from the API
      // For now, we'll use the mock data
      setFeaturedArtists(mockArtists.slice(0, 4));
      setLatestPodcasts(mockPodcasts.slice(0, 3));
      setRecentPosts(mockBlogPosts.slice(0, 3));
    } catch (e) {
      console.error(e, `Error fetching data from API`);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handlePlayTrack = (artistId) => {
    const track = mockTracks.find(track => track.artistId === artistId);
    if (track) {
      playTrack(track);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <section className="mb-12">
        <div className="bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg p-8 shadow-xl">
          <h1 className="text-4xl font-bold mb-4">Welcome to itsyourradio</h1>
          <p className="text-xl mb-6">Your place for the best music and podcasts.</p>
          <p className="mb-6">API Message: {message}</p>
          <div className="flex flex-wrap space-x-0 space-y-2 sm:space-x-4 sm:space-y-0">
            <button
              onClick={toggleLiveStream}
              className="bg-red-500 text-white px-6 py-2 rounded-full font-semibold hover:bg-red-600 transition-colors flex items-center"
            >
              <span className="mr-2">Listen Live</span>
              <span className="animate-pulse">●</span>
            </button>
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
          {featuredArtists.map(artist => (
            <div key={artist.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
              <div 
                className="h-48 bg-gray-200 rounded-md mb-4 bg-cover bg-center cursor-pointer" 
                style={{ backgroundImage: `url(${artist.image})` }}
                onClick={() => handlePlayTrack(artist.id)}
              >
                <div className="flex justify-center items-center h-full bg-black bg-opacity-50 opacity-0 hover:opacity-100 transition-opacity rounded-md">
                  <div className="text-white text-xl">▶ Play</div>
                </div>
              </div>
              <h3 className="text-xl font-semibold">{artist.name}</h3>
              <p className="text-gray-600">{artist.genre}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-3xl font-bold mb-6">Latest Podcasts</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {latestPodcasts.map(podcast => (
            <div key={podcast.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
              <div 
                className="h-48 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
                style={{ backgroundImage: `url(${podcast.coverImage})` }}
              ></div>
              <h3 className="text-xl font-semibold">{podcast.title}</h3>
              <p className="text-gray-600">{podcast.host}</p>
              <p className="text-gray-500 text-sm mt-2">Latest Episode: {podcast.latestEpisode.title}</p>
            </div>
          ))}
        </div>
      </section>

      <section>
        <h2 className="text-3xl font-bold mb-6">Recent Blog Posts</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {recentPosts.map(post => (
            <div key={post.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
              <div 
                className="h-48 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
                style={{ backgroundImage: `url(${post.featuredImage})` }}
              ></div>
              <h3 className="text-xl font-semibold">{post.title}</h3>
              <p className="text-gray-600">{post.author}</p>
              <p className="text-gray-500 text-sm mt-2">Published: {post.publishedAt}</p>
              <p className="mt-2">{post.excerpt}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

// Artists page (with data)
const Artists = () => {
  const { playTrack } = useContext(AudioPlayerContext);
  const [artists, setArtists] = useState([]);

  useEffect(() => {
    // In a real application, we would fetch this data from the API
    // For now, we'll use the mock data
    setArtists(mockArtists);
  }, []);

  const handlePlayTrack = (artistId) => {
    const track = mockTracks.find(track => track.artistId === artistId);
    if (track) {
      playTrack(track);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Artists</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {artists.map(artist => (
          <div key={artist.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div 
              className="h-64 bg-gray-200 rounded-md mb-4 bg-cover bg-center cursor-pointer" 
              style={{ backgroundImage: `url(${artist.image})` }}
              onClick={() => handlePlayTrack(artist.id)}
            >
              <div className="flex justify-center items-center h-full bg-black bg-opacity-50 opacity-0 hover:opacity-100 transition-opacity rounded-md">
                <div className="text-white text-xl">▶ Play</div>
              </div>
            </div>
            <h3 className="text-xl font-semibold">{artist.name}</h3>
            <p className="text-gray-600">{artist.genre}</p>
            <p className="mt-2 text-gray-700">{artist.bio}</p>
            <div className="mt-4">
              <Link 
                to={`/artists/${artist.id}`} 
                className="text-purple-600 hover:text-purple-800 font-medium"
              >
                View Profile
              </Link>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Podcasts page (with data)
const Podcasts = () => {
  const [podcasts, setPodcasts] = useState([]);

  useEffect(() => {
    // In a real application, we would fetch this data from the API
    // For now, we'll use the mock data
    setPodcasts(mockPodcasts);
  }, []);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Podcasts</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {podcasts.map(podcast => (
          <div key={podcast.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div 
              className="h-64 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
              style={{ backgroundImage: `url(${podcast.coverImage})` }}
            ></div>
            <h3 className="text-xl font-semibold">{podcast.title}</h3>
            <p className="text-gray-600">Host: {podcast.host}</p>
            <p className="mt-2 text-gray-700">{podcast.description}</p>
            <div className="mt-4 p-3 bg-gray-100 rounded-md">
              <p className="font-medium">Latest Episode:</p>
              <p className="text-gray-700">{podcast.latestEpisode.title}</p>
              <p className="text-gray-500 text-sm">Released: {podcast.latestEpisode.publishedAt}</p>
            </div>
            <div className="mt-4">
              <Link 
                to={`/podcasts/${podcast.id}`} 
                className="text-purple-600 hover:text-purple-800 font-medium"
              >
                Listen Now
              </Link>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Blog page (with data)
const Blog = () => {
  const [posts, setPosts] = useState([]);

  useEffect(() => {
    // In a real application, we would fetch this data from the API
    // For now, we'll use the mock data
    setPosts(mockBlogPosts);
  }, []);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Blog</h1>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {posts.map(post => (
          <div key={post.id} className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div 
              className="h-64 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
              style={{ backgroundImage: `url(${post.featuredImage})` }}
            ></div>
            <h2 className="text-2xl font-bold mb-2">{post.title}</h2>
            <div className="flex items-center text-gray-600 mb-4">
              <span>{post.author}</span>
              <span className="mx-2">•</span>
              <span>{post.publishedAt}</span>
            </div>
            <p className="text-gray-700 mb-4">{post.excerpt}</p>
            <Link 
              to={`/blog/${post.id}`} 
              className="inline-block bg-purple-600 text-white px-4 py-2 rounded-md hover:bg-purple-700 transition-colors"
            >
              Read More
            </Link>
          </div>
        ))}
      </div>
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
    return <div className="flex items-center justify-center h-screen">Loading...</div>;
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
EOL
check_error "Failed to update App.js"

# Add custom CSS for the player
cat >> "$FRONTEND_SRC/src/App.css" << 'EOL'

/* Enhanced Audio Player Styles */
.range-input {
  -webkit-appearance: none;
  appearance: none;
  width: 100%;
  height: 4px;
  background: rgba(255, 255, 255, 0.3);
  outline: none;
  border-radius: 4px;
  overflow: hidden;
}

.range-input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 12px;
  height: 12px;
  background: white;
  border-radius: 50%;
  cursor: pointer;
  box-shadow: 0 0 2px rgba(0, 0, 0, 0.3);
}

.range-input::-moz-range-thumb {
  width: 12px;
  height: 12px;
  background: white;
  border-radius: 50%;
  cursor: pointer;
  border: none;
  box-shadow: 0 0 2px rgba(0, 0, 0, 0.3);
}

/* Live Radio Button Styles */
.live-radio-btn {
  position: relative;
}

.live-indicator {
  position: absolute;
  top: -4px;
  right: -4px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgb(220, 38, 38);
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    opacity: 0.6;
    transform: scale(0.9);
  }
  50% {
    opacity: 1;
    transform: scale(1.1);
  }
  100% {
    opacity: 0.6;
    transform: scale(0.9);
  }
}
EOL
check_error "Failed to update App.css"

# Build the frontend
log_message "Building the frontend with updated components..."
cd "$FRONTEND_SRC"

# Determine which package manager to use
if command -v yarn &> /dev/null; then
    yarn build
    check_error "Failed to build frontend"
elif command -v npm &> /dev/null; then
    npm run build
    check_error "Failed to build frontend"
else
    log_error "Neither yarn nor npm is available. Cannot build frontend."
    exit 1
fi

# Copy build files to the public_html directory
cp -r build/* "$PUBLIC_HTML/"
check_error "Failed to copy frontend build files"

log_message "✓ Frontend rebuilt successfully with the new audio player"

log_message "All fixes have been applied successfully!"