import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import FileUploader from '../../components/upload/FileUploader';

const PodcasterDashboard = () => {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('shows');
  const [uploadSuccess, setUploadSuccess] = useState(null);
  const [uploadError, setUploadError] = useState(null);
  
  // Mock data for podcast shows
  const [shows, setShows] = useState([
    {
      id: '1',
      title: 'Tech Talk Weekly',
      description: 'Weekly discussions about the latest in technology',
      episodeCount: 25,
      isOriginal: true,
      isClassic: false,
      coverArt: 'https://images.unsplash.com/photo-1589903308904-1010c2294adc?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60'
    },
    {
      id: '2',
      title: 'Music History',
      description: 'Exploring the evolution of music through the decades',
      episodeCount: 12,
      isOriginal: false,
      isClassic: true,
      coverArt: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60'
    }
  ]);
  
  // Mock data for episodes
  const [episodes, setEpisodes] = useState([
    {
      id: '1',
      showId: '1',
      title: 'Episode 25: AI Revolution',
      description: 'Discussing the latest developments in artificial intelligence',
      publishedAt: '2023-06-01',
      duration: 3600 // 60 minutes in seconds
    },
    {
      id: '2',
      showId: '1',
      title: 'Episode 24: Blockchain Explained',
      description: 'A deep dive into blockchain technology',
      publishedAt: '2023-05-25',
      duration: 2700 // 45 minutes in seconds
    },
    {
      id: '3',
      showId: '2',
      title: 'Episode 12: The 80s Synth Wave',
      description: 'Exploring the iconic synth wave movement of the 1980s',
      publishedAt: '2023-06-05',
      duration: 3300 // 55 minutes in seconds
    }
  ]);
  
  // Redirect if not logged in or not a podcaster
  if (loading) {
    return (
      <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-500"></div>
      </div>
    );
  }
  
  if (!user || user.role !== 'podcaster') {
    return <Navigate to="/login" />;
  }
  
  const handleUploadSuccess = (data) => {
    setUploadSuccess('File uploaded successfully!');
    setUploadError(null);
    setTimeout(() => setUploadSuccess(null), 5000);
    
    // Here you would typically update your state with the new file data
    console.log('Upload success:', data);
  };
  
  const handleUploadError = (error) => {
    setUploadError('Failed to upload file. Please try again.');
    setUploadSuccess(null);
    setTimeout(() => setUploadError(null), 5000);
  };
  
  // Format duration from seconds to MM:SS
  const formatDuration = (seconds) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds < 10 ? '0' : ''}${remainingSeconds}`;
  };
  
  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">Podcaster Dashboard</h1>
        
        {/* Tabs */}
        <div className="mb-8 border-b border-gray-700">
          <nav className="flex space-x-8">
            <button
              onClick={() => setActiveTab('shows')}
              className={`pb-4 px-1 ${
                activeTab === 'shows'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Shows
            </button>
            <button
              onClick={() => setActiveTab('episodes')}
              className={`pb-4 px-1 ${
                activeTab === 'episodes'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Episodes
            </button>
            <button
              onClick={() => setActiveTab('profile')}
              className={`pb-4 px-1 ${
                activeTab === 'profile'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Profile
            </button>
            <button
              onClick={() => setActiveTab('rss')}
              className={`pb-4 px-1 ${
                activeTab === 'rss'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              RSS Feed
            </button>
          </nav>
        </div>
        
        {/* Status Messages */}
        {uploadSuccess && (
          <div className="bg-green-500/20 border border-green-500 text-green-100 px-4 py-3 rounded mb-6">
            {uploadSuccess}
          </div>
        )}
        
        {uploadError && (
          <div className="bg-red-500/20 border border-red-500 text-red-100 px-4 py-3 rounded mb-6">
            {uploadError}
          </div>
        )}
        
        {/* Tab Content */}
        <div className="mt-6">
          {/* Shows Tab */}
          {activeTab === 'shows' && (
            <div>
              <div className="bg-gray-800 rounded-lg p-6 mb-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-bold">Your Shows</h2>
                  <button className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors">
                    Create New Show
                  </button>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {shows.map(show => (
                    <div key={show.id} className="bg-gray-700 rounded-lg overflow-hidden">
                      <div className="relative">
                        <img 
                          src={show.coverArt} 
                          alt={show.title} 
                          className="w-full h-48 object-cover"
                        />
                        {show.isOriginal && (
                          <span className="absolute top-2 right-2 bg-purple-600 text-white text-xs px-2 py-1 rounded">
                            IYR Original
                          </span>
                        )}
                        {show.isClassic && (
                          <span className="absolute top-2 right-2 bg-blue-600 text-white text-xs px-2 py-1 rounded">
                            IYR Classic
                          </span>
                        )}
                      </div>
                      <div className="p-4">
                        <h3 className="text-lg font-bold">{show.title}</h3>
                        <p className="text-gray-300 text-sm mb-2">{show.description}</p>
                        <p className="text-gray-400 text-sm">{show.episodeCount} episodes</p>
                        <div className="mt-3">
                          <button className="text-purple-400 hover:text-purple-300 transition mr-3">Edit</button>
                          <button className="text-purple-400 hover:text-purple-300 transition">Manage Episodes</button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="bg-gray-800 rounded-lg p-6">
                <h2 className="text-xl font-bold mb-4">Upload Show Cover Art</h2>
                <FileUploader 
                  endpoint="/api/upload/podcast-cover"
                  acceptedFileTypes="image/*"
                  maxFileSizeMB={5}
                  onUploadSuccess={handleUploadSuccess}
                  onUploadError={handleUploadError}
                  buttonText="Upload Cover Art"
                />
              </div>
            </div>
          )}
          
          {/* Episodes Tab */}
          {activeTab === 'episodes' && (
            <div>
              <div className="bg-gray-800 rounded-lg p-6 mb-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-bold">Your Episodes</h2>
                  <button className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors">
                    Create New Episode
                  </button>
                </div>
                
                {episodes.length > 0 ? (
                  <div className="space-y-4">
                    {episodes.map(episode => {
                      const show = shows.find(s => s.id === episode.showId);
                      return (
                        <div key={episode.id} className="bg-gray-700 rounded-lg p-4 flex flex-col md:flex-row">
                          <div className="md:w-1/4 mb-4 md:mb-0 md:mr-4">
                            <img 
                              src={show?.coverArt || 'https://via.placeholder.com/300?text=Podcast'} 
                              alt={episode.title} 
                              className="w-full h-32 object-cover rounded-lg"
                            />
                          </div>
                          <div className="md:w-3/4">
                            <h3 className="text-lg font-bold">{episode.title}</h3>
                            <p className="text-purple-400 text-sm mb-2">{show?.title || 'Unknown Show'}</p>
                            <p className="text-gray-300 mb-2">{episode.description}</p>
                            <div className="flex flex-wrap items-center text-sm text-gray-400 mb-3">
                              <span className="mr-4">
                                Published: {new Date(episode.publishedAt).toLocaleDateString()}
                              </span>
                              <span>
                                Duration: {formatDuration(episode.duration)}
                              </span>
                            </div>
                            <div className="flex space-x-3">
                              <button className="text-purple-400 hover:text-purple-300 transition">Edit</button>
                              <button className="text-purple-400 hover:text-purple-300 transition">Delete</button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <p className="text-gray-400">You haven't created any episodes yet.</p>
                )}
              </div>
              
              <div className="bg-gray-800 rounded-lg p-6">
                <h2 className="text-xl font-bold mb-4">Upload Podcast Episode</h2>
                <FileUploader 
                  endpoint="/api/upload/podcast"
                  acceptedFileTypes="audio/mpeg,audio/mp3"
                  maxFileSizeMB={50}
                  onUploadSuccess={handleUploadSuccess}
                  onUploadError={handleUploadError}
                  buttonText="Upload Episode"
                  additionalFields={{
                    show_name: shows.length > 0 ? shows[0].title : "Default Show"
                  }}
                />
              </div>
            </div>
          )}
          
          {/* Profile Tab */}
          {activeTab === 'profile' && (
            <div>
              <div className="bg-gray-800 rounded-lg p-6">
                <h2 className="text-xl font-bold mb-4">Podcaster Profile</h2>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div className="col-span-1">
                    <div className="bg-gray-700 rounded-lg p-4 flex flex-col items-center">
                      <img 
                        src={user.profile_image_url || "https://via.placeholder.com/150?text=Profile"} 
                        alt={user.username} 
                        className="w-32 h-32 rounded-full object-cover mb-4"
                      />
                      <h3 className="text-lg font-bold">{user.full_name || user.username}</h3>
                      <p className="text-gray-400 text-sm">Podcaster</p>
                      
                      <div className="mt-4 w-full">
                        <h4 className="text-sm font-medium mb-2">Upload Profile Image</h4>
                        <FileUploader 
                          endpoint="/api/upload/profile-image"
                          acceptedFileTypes="image/*"
                          maxFileSizeMB={5}
                          onUploadSuccess={handleUploadSuccess}
                          onUploadError={handleUploadError}
                          buttonText="Upload Image"
                        />
                      </div>
                    </div>
                  </div>
                  
                  <div className="col-span-2">
                    <div className="bg-gray-700 rounded-lg p-4">
                      <h3 className="text-lg font-bold mb-4">Podcaster Information</h3>
                      
                      <form className="space-y-4">
                        <div>
                          <label className="block text-sm font-medium mb-1">Full Name</label>
                          <input 
                            type="text"
                            className="w-full bg-gray-800 rounded-md py-2 px-4"
                            placeholder="Your full name"
                            defaultValue={user.full_name || ''}
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium mb-1">Biography</label>
                          <textarea 
                            className="w-full bg-gray-800 rounded-md py-2 px-4 min-h-[150px]"
                            placeholder="Tell us about yourself and your podcasts"
                            defaultValue={user.bio || ''}
                          ></textarea>
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium mb-1">Contact Email</label>
                          <input 
                            type="email"
                            className="w-full bg-gray-800 rounded-md py-2 px-4"
                            placeholder="podcast@example.com"
                            defaultValue={user.email}
                          />
                          <p className="text-xs text-gray-400 mt-1">This email will be used for podcast RSS feed information</p>
                        </div>
                        
                        <button 
                          type="submit"
                          className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors"
                        >
                          Save Changes
                        </button>
                      </form>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
          
          {/* RSS Feed Tab */}
          {activeTab === 'rss' && (
            <div className="bg-gray-800 rounded-lg p-6">
              <h2 className="text-xl font-bold mb-6">RSS Feeds</h2>
              <p className="text-gray-300 mb-6">
                Use these RSS feed URLs to submit your podcasts to platforms like Apple Podcasts, Spotify, Google Podcasts, and more.
              </p>
              
              {shows.length > 0 ? (
                <div className="space-y-6">
                  {shows.map(show => (
                    <div key={show.id} className="bg-gray-700 rounded-lg p-4">
                      <div className="flex items-center mb-4">
                        <img 
                          src={show.coverArt} 
                          alt={show.title} 
                          className="w-16 h-16 rounded-md object-cover mr-4"
                        />
                        <div>
                          <h3 className="font-bold">{show.title}</h3>
                          <p className="text-gray-400 text-sm">{show.episodeCount} episodes</p>
                        </div>
                      </div>
                      <div className="mb-4">
                        <label className="block text-sm font-medium mb-2">RSS Feed URL</label>
                        <div className="flex">
                          <input 
                            type="text"
                            readOnly
                            className="flex-grow bg-gray-800 rounded-l-md py-2 px-4"
                            value={`${process.env.REACT_APP_BACKEND_URL}/api/podcasts/${show.id}/rss`}
                          />
                          <button 
                            className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-r-md font-medium transition-colors"
                            onClick={() => {
                              navigator.clipboard.writeText(`${process.env.REACT_APP_BACKEND_URL}/api/podcasts/${show.id}/rss`);
                              alert('RSS URL copied to clipboard!');
                            }}
                          >
                            Copy
                          </button>
                        </div>
                      </div>
                      <div className="flex flex-wrap space-x-3">
                        <a 
                          href="https://podcasters.apple.com/support/897-submit-a-podcast" 
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-purple-400 hover:text-purple-300 transition"
                        >
                          Submit to Apple Podcasts
                        </a>
                        <a 
                          href="https://podcasters.spotify.com/submit" 
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-purple-400 hover:text-purple-300 transition"
                        >
                          Submit to Spotify
                        </a>
                        <a 
                          href="https://podcastsmanager.google.com/add-feed" 
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-purple-400 hover:text-purple-300 transition"
                        >
                          Submit to Google Podcasts
                        </a>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="bg-gray-700 rounded-lg p-6 text-center">
                  <p className="text-gray-400 mb-4">You don't have any podcast shows yet.</p>
                  <button 
                    onClick={() => setActiveTab('shows')}
                    className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors"
                  >
                    Create Your First Show
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PodcasterDashboard;
