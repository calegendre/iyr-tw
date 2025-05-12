import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';

const Artists = () => {
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchArtists = async () => {
      try {
        const response = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/api/artists`);
        setArtists(response.data);
      } catch (err) {
        console.error('Error fetching artists:', err);
        setError('Failed to load artists. Please try again later.');
        
        // For demo purposes, add some sample artists when API fails
        setArtists([
          {
            id: '1',
            username: 'jazzmasters',
            full_name: 'The Jazz Masters',
            bio: 'A collective of jazz musicians pushing the boundaries of modern jazz.',
            profile_image_url: 'https://images.unsplash.com/photo-1511192336575-5a79af67a629?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
          },
          {
            id: '2',
            username: 'electrobeats',
            full_name: 'Electro Beats',
            bio: 'Electronic music producer creating innovative soundscapes and beats.',
            profile_image_url: 'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
          },
          {
            id: '3',
            username: 'acousticvibes',
            full_name: 'Acoustic Vibes',
            bio: 'Folk musician specializing in introspective lyrics and acoustic arrangements.',
            profile_image_url: 'https://images.unsplash.com/photo-1549213783-8284d0336c4f?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
          }
        ]);
      } finally {
        setLoading(false);
      }
    };

    fetchArtists();
  }, []);

  if (loading) {
    return (
      <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
        <div className="container mx-auto px-4 py-16">
          <h1 className="text-4xl font-bold mb-8 text-center">Artists</h1>
          <div className="flex justify-center">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-500"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      <div className="container mx-auto px-4 py-16">
        <h1 className="text-4xl font-bold mb-8 text-center">Artists</h1>
        
        {error && (
          <div className="bg-red-500/20 border border-red-500 text-red-100 px-4 py-3 rounded mb-6 max-w-3xl mx-auto">
            {error}
          </div>
        )}
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {artists.map((artist) => (
            <Link 
              key={artist.id}
              to={`/artists/${artist.id}`}
              className="bg-gray-800 rounded-lg overflow-hidden shadow-lg hover:shadow-xl transition-shadow"
            >
              <div className="h-56 bg-gray-700 overflow-hidden">
                <img 
                  src={artist.profile_image_url || 'https://via.placeholder.com/500x300?text=No+Image'} 
                  alt={artist.full_name || artist.username}
                  className="w-full h-full object-cover transform hover:scale-105 transition-transform"
                />
              </div>
              <div className="p-6">
                <h2 className="text-xl font-bold mb-2">{artist.full_name || artist.username}</h2>
                {artist.bio && (
                  <p className="text-gray-300 line-clamp-3">{artist.bio}</p>
                )}
                <div className="mt-4 inline-block bg-purple-600 text-white px-3 py-1 rounded-md text-sm">
                  View Profile
                </div>
              </div>
            </Link>
          ))}
        </div>
        
        {artists.length === 0 && !error && (
          <div className="text-center text-gray-400">
            <p className="text-xl">No artists found.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Artists;
