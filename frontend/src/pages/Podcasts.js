import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';
import { useMediaPlayer } from '../contexts/MediaPlayerContext';

const PodcastCard = ({ podcast, onPlayEpisode }) => {
  const [expanded, setExpanded] = useState(false);
  const [episodes, setEpisodes] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchEpisodes = async () => {
    if (!expanded) {
      setLoading(true);
      try {
        const response = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/api/podcasts/${podcast.id}/episodes`);
        setEpisodes(response.data);
      } catch (err) {
        console.error('Error fetching episodes:', err);
        // For demo purposes, add some sample episodes
        setEpisodes([
          {
            id: '101',
            title: 'Episode 1: Introduction',
            description: 'The first episode introducing the show and its format.',
            published_at: '2023-01-15T12:00:00Z',
            duration: 1845 // 30:45
          },
          {
            id: '102',
            title: 'Episode 2: Special Guest Interview',
            description: 'An interview with a special guest in the industry.',
            published_at: '2023-02-01T12:00:00Z',
            duration: 3600 // 60:00
          }
        ]);
      } finally {
        setLoading(false);
      }
    }
    setExpanded(!expanded);
  };

  return (
    <div className="bg-gray-800 rounded-lg overflow-hidden shadow-lg">
      <div className="h-48 bg-gray-700 overflow-hidden">
        <img 
          src={podcast.cover_art_url || 'https://via.placeholder.com/500x300?text=Podcast+Cover'} 
          alt={podcast.title}
          className="w-full h-full object-cover"
        />
      </div>
      <div className="p-6">
        <div className="flex items-start justify-between">
          <h2 className="text-xl font-bold mb-2">{podcast.title}</h2>
          {podcast.is_original && (
            <span className="bg-purple-600 text-white text-xs px-2 py-1 rounded">IYR Original</span>
          )}
          {podcast.is_classic && (
            <span className="bg-blue-600 text-white text-xs px-2 py-1 rounded">IYR Classic</span>
          )}
        </div>
        <p className="text-gray-300 mb-4 line-clamp-2">{podcast.description}</p>
        
        <button 
          onClick={fetchEpisodes}
          className="flex items-center text-purple-400 hover:text-purple-300 transition"
        >
          {expanded ? 'Hide Episodes' : 'Show Episodes'}
          <svg 
            xmlns="http://www.w3.org/2000/svg" 
            className={`h-4 w-4 ml-1 transition-transform ${expanded ? 'rotate-180' : 'rotate-0'}`} 
            fill="none" 
            viewBox="0 0 24 24" 
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>
        
        {expanded && (
          <div className="mt-4 border-t border-gray-700 pt-4">
            <h3 className="text-lg font-semibold mb-2">Episodes</h3>
            
            {loading ? (
              <div className="flex justify-center py-4">
                <div className="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-purple-500"></div>
              </div>
            ) : episodes.length > 0 ? (
              <ul className="space-y-3">
                {episodes.map((episode) => (
                  <li key={episode.id} className="border-b border-gray-700 pb-3 last:border-0">
                    <div className="flex justify-between items-start">
                      <div>
                        <h4 className="font-medium">{episode.title}</h4>
                        <p className="text-sm text-gray-400 mt-1">{new Date(episode.published_at).toLocaleDateString()}</p>
                      </div>
                      <button 
                        onClick={() => onPlayEpisode(podcast, episode)}
                        className="bg-purple-600 hover:bg-purple-700 text-white p-2 rounded-full"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                        </svg>
                      </button>
                    </div>
                    <p className="text-sm text-gray-300 mt-1 line-clamp-2">{episode.description}</p>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-gray-400 py-2">No episodes available.</p>
            )}
            
            <Link 
              to={`/podcasts/${podcast.id}`}
              className="inline-block mt-4 bg-purple-600 hover:bg-purple-700 text-white px-3 py-1 rounded-md text-sm transition"
            >
              View Full Show
            </Link>
          </div>
        )}
      </div>
    </div>
  );
};

const Podcasts = () => {
  const [podcasts, setPodcasts] = useState([]);
  const [originals, setOriginals] = useState([]);
  const [classics, setClassics] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const { playPodcast } = useMediaPlayer();

  useEffect(() => {
    const fetchPodcasts = async () => {
      try {
        // Get all podcasts
        const response = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/api/podcasts`);
        setPodcasts(response.data);
        
        // Get originals
        const originalsResponse = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/api/podcasts/originals`);
        setOriginals(originalsResponse.data);
        
        // Get classics
        const classicsResponse = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/api/podcasts/classics`);
        setClassics(classicsResponse.data);
      } catch (err) {
        console.error('Error fetching podcasts:', err);
        setError('Failed to load podcasts. Please try again later.');
        
        // For demo purposes, add some sample podcasts
        const samplePodcasts = [
          {
            id: '1',
            title: 'The Music Hour',
            description: 'A weekly discussion about music trends and history.',
            host_id: '101',
            cover_art_url: 'https://images.unsplash.com/photo-1516223725307-6f76b9ec8742?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
            is_original: true,
            is_classic: false
          },
          {
            id: '2',
            title: 'Tech Beat',
            description: 'Exploring the intersection of technology and music production.',
            host_id: '102',
            cover_art_url: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
            is_original: true,
            is_classic: false
          },
          {
            id: '3',
            title: 'Classic Album Reviews',
            description: 'Revisiting and analyzing the most influential albums of all time.',
            host_id: '103',
            cover_art_url: 'https://images.unsplash.com/photo-1545114687-ab1c435a9e30?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
            is_original: false,
            is_classic: true
          }
        ];
        
        setPodcasts(samplePodcasts);
        setOriginals(samplePodcasts.filter(p => p.is_original));
        setClassics(samplePodcasts.filter(p => p.is_classic));
      } finally {
        setLoading(false);
      }
    };

    fetchPodcasts();
  }, []);

  const handlePlayEpisode = (podcast, episode) => {
    // In a real app, you'd have the actual file URL
    const fileUrl = `${process.env.REACT_APP_BACKEND_URL}/${episode.file_path || `podcasts/${podcast.id}/episode-${episode.id}.mp3`}`;
    
    playPodcast({
      title: episode.title,
      host: podcast.title,
      coverArt: podcast.cover_art_url,
      fileUrl: fileUrl
    });
  };

  if (loading) {
    return (
      <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
        <div className="container mx-auto px-4 py-16">
          <h1 className="text-4xl font-bold mb-8 text-center">Podcasts</h1>
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
        <h1 className="text-4xl font-bold mb-8 text-center">Podcasts</h1>
        
        {error && (
          <div className="bg-red-500/20 border border-red-500 text-red-100 px-4 py-3 rounded mb-6 max-w-3xl mx-auto">
            {error}
          </div>
        )}
        
        {/* IYR Originals */}
        <section className="mb-12">
          <h2 className="text-2xl font-bold mb-6 flex items-center">
            <span className="bg-purple-600 h-6 w-2 mr-3"></span>
            IYR Originals
          </h2>
          {originals.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {originals.map((podcast) => (
                <PodcastCard 
                  key={podcast.id} 
                  podcast={podcast} 
                  onPlayEpisode={handlePlayEpisode}
                />
              ))}
            </div>
          ) : (
            <p className="text-gray-400">No original podcasts available.</p>
          )}
        </section>
        
        {/* IYR Classics */}
        <section className="mb-12">
          <h2 className="text-2xl font-bold mb-6 flex items-center">
            <span className="bg-blue-600 h-6 w-2 mr-3"></span>
            IYR Classics
          </h2>
          {classics.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {classics.map((podcast) => (
                <PodcastCard 
                  key={podcast.id} 
                  podcast={podcast} 
                  onPlayEpisode={handlePlayEpisode}
                />
              ))}
            </div>
          ) : (
            <p className="text-gray-400">No classic podcasts available.</p>
          )}
        </section>
        
        {/* All Shows */}
        {podcasts.some(p => !p.is_original && !p.is_classic) && (
          <section>
            <h2 className="text-2xl font-bold mb-6 flex items-center">
              <span className="bg-gray-400 h-6 w-2 mr-3"></span>
              All Shows
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {podcasts
                .filter(p => !p.is_original && !p.is_classic)
                .map((podcast) => (
                  <PodcastCard 
                    key={podcast.id} 
                    podcast={podcast} 
                    onPlayEpisode={handlePlayEpisode}
                  />
                ))
              }
            </div>
          </section>
        )}
      </div>
    </div>
  );
};

export default Podcasts;
