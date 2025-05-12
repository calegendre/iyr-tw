import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import FileUploader from '../../components/upload/FileUploader';

const ArtistDashboard = () => {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('profile');
  const [uploadSuccess, setUploadSuccess] = useState(null);
  const [uploadError, setUploadError] = useState(null);
  
  // Mock data for albums
  const [albums, setAlbums] = useState([
    {
      id: '1',
      title: 'Summer Vibes',
      releaseDate: '2023-06-15',
      songCount: 12,
      coverArt: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60'
    },
    {
      id: '2',
      title: 'Midnight Sessions',
      releaseDate: '2022-11-30',
      songCount: 8,
      coverArt: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60'
    }
  ]);
  
  // Mock data for blog posts
  const [posts, setPosts] = useState([
    {
      id: '1',
      title: 'New Album Coming Soon',
      publishedAt: '2023-05-20',
      excerpt: 'Exciting news! My new album will be released next month...'
    },
    {
      id: '2',
      title: 'Tour Dates Announced',
      publishedAt: '2023-04-10',
      excerpt: 'Check out the upcoming tour dates for this summer...'
    }
  ]);
  
  // Redirect if not logged in or not an artist
  if (loading) {
    return (
      <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-500"></div>
      </div>
    );
  }
  
  if (!user || user.role !== 'artist') {
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
  
  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">Artist Dashboard</h1>
        
        {/* Tabs */}
        <div className="mb-8 border-b border-gray-700">
          <nav className="flex space-x-8">
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
              onClick={() => setActiveTab('music')}
              className={`pb-4 px-1 ${
                activeTab === 'music'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Music
            </button>
            <button
              onClick={() => setActiveTab('blog')}
              className={`pb-4 px-1 ${
                activeTab === 'blog'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Blog
            </button>
            <button
              onClick={() => setActiveTab('stats')}
              className={`pb-4 px-1 ${
                activeTab === 'stats'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Stats
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
          {/* Profile Tab */}
          {activeTab === 'profile' && (
            <div>
              <div className="bg-gray-800 rounded-lg p-6 mb-6">
                <h2 className="text-xl font-bold mb-4">Artist Profile</h2>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div className="col-span-1">
                    <div className="bg-gray-700 rounded-lg p-4 flex flex-col items-center">
                      <img 
                        src={user.profile_image_url || "https://via.placeholder.com/150?text=Profile"} 
                        alt={user.username} 
                        className="w-32 h-32 rounded-full object-cover mb-4"
                      />
                      <h3 className="text-lg font-bold">{user.full_name || user.username}</h3>
                      <p className="text-gray-400 text-sm">Artist</p>
                      
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
                      <h3 className="text-lg font-bold mb-4">Artist Information</h3>
                      
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
                            placeholder="Tell us about yourself"
                            defaultValue={user.bio || ''}
                          ></textarea>
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium mb-1">Spotify Artist URL</label>
                          <input 
                            type="text"
                            className="w-full bg-gray-800 rounded-md py-2 px-4"
                            placeholder="https://open.spotify.com/artist/..."
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium mb-1">YouTube Video URL</label>
                          <input 
                            type="text"
                            className="w-full bg-gray-800 rounded-md py-2 px-4"
                            placeholder="https://youtube.com/watch?v=..."
                          />
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
              
              <div className="bg-gray-800 rounded-lg p-6">
                <h2 className="text-xl font-bold mb-4">Cover Image</h2>
                <div className="mb-4">
                  <img 
                    src={user.cover_image_url || "https://via.placeholder.com/1200x300?text=Cover+Image"} 
                    alt="Cover" 
                    className="w-full h-48 object-cover rounded-lg"
                  />
                </div>
                <FileUploader 
                  endpoint="/api/upload/cover-image"
                  acceptedFileTypes="image/*"
                  maxFileSizeMB={10}
                  onUploadSuccess={handleUploadSuccess}
                  onUploadError={handleUploadError}
                  buttonText="Upload Cover Image"
                />
              </div>
            </div>
          )}
          
          {/* Music Tab */}
          {activeTab === 'music' && (
            <div>
              <div className="bg-gray-800 rounded-lg p-6 mb-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-bold">Your Albums</h2>
                  <button className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors">
                    Create New Album
                  </button>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {albums.map(album => (
                    <div key={album.id} className="bg-gray-700 rounded-lg overflow-hidden">
                      <img 
                        src={album.coverArt} 
                        alt={album.title} 
                        className="w-full h-40 object-cover"
                      />
                      <div className="p-4">
                        <h3 className="text-lg font-bold">{album.title}</h3>
                        <p className="text-gray-400 text-sm">Released: {new Date(album.releaseDate).toLocaleDateString()}</p>
                        <p className="text-gray-400 text-sm">{album.songCount} songs</p>
                        <div className="mt-3">
                          <button className="text-purple-400 hover:text-purple-300 transition mr-3">Edit</button>
                          <button className="text-purple-400 hover:text-purple-300 transition">View Songs</button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="bg-gray-800 rounded-lg p-6">
                <h2 className="text-xl font-bold mb-4">Upload Music</h2>
                <p className="text-gray-300 mb-4">
                  Upload your music files here. They will be stored securely and added to your radio station library.
                </p>
                <FileUploader 
                  endpoint="/api/upload/music"
                  acceptedFileTypes="audio/mpeg,audio/mp3"
                  maxFileSizeMB={30}
                  onUploadSuccess={handleUploadSuccess}
                  onUploadError={handleUploadError}
                  buttonText="Upload Music"
                  additionalFields={{
                    artist_name: user.full_name || user.username,
                    album_name: "Singles"
                  }}
                />
              </div>
            </div>
          )}
          
          {/* Blog Tab */}
          {activeTab === 'blog' && (
            <div>
              <div className="bg-gray-800 rounded-lg p-6 mb-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-bold">Your Blog Posts</h2>
                  <button className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors">
                    Create New Post
                  </button>
                </div>
                
                {posts.length > 0 ? (
                  <div className="space-y-4">
                    {posts.map(post => (
                      <div key={post.id} className="bg-gray-700 rounded-lg p-4">
                        <h3 className="text-lg font-bold">{post.title}</h3>
                        <p className="text-gray-400 text-sm mb-2">Published: {new Date(post.publishedAt).toLocaleDateString()}</p>
                        <p className="text-gray-300 mb-3">{post.excerpt}</p>
                        <div className="flex space-x-3">
                          <button className="text-purple-400 hover:text-purple-300 transition">Edit</button>
                          <button className="text-purple-400 hover:text-purple-300 transition">Delete</button>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-gray-400">You haven't created any blog posts yet.</p>
                )}
              </div>
            </div>
          )}
          
          {/* Stats Tab */}
          {activeTab === 'stats' && (
            <div className="bg-gray-800 rounded-lg p-6">
              <h2 className="text-xl font-bold mb-6">Stats & Analytics</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div className="bg-gray-700 rounded-lg p-4 text-center">
                  <p className="text-4xl font-bold text-purple-400">1,234</p>
                  <p className="text-gray-400">Total Plays</p>
                </div>
                <div className="bg-gray-700 rounded-lg p-4 text-center">
                  <p className="text-4xl font-bold text-purple-400">56</p>
                  <p className="text-gray-400">Blog Views</p>
                </div>
                <div className="bg-gray-700 rounded-lg p-4 text-center">
                  <p className="text-4xl font-bold text-purple-400">78</p>
                  <p className="text-gray-400">Profile Views</p>
                </div>
              </div>
              
              <p className="text-gray-300 text-center">
                More detailed analytics coming soon!
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ArtistDashboard;
