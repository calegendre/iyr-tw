import React from 'react';
import { useMediaPlayer } from '../contexts/MediaPlayerContext';
import streamConfig from '../config/streamConfig';

const Home = () => {
  const { isPlaying, setIsPlaying, playLiveRadio } = useMediaPlayer();

  const handlePlayClick = () => {
    if (!isPlaying) {
      playLiveRadio();
    } else {
      setIsPlaying(false);
    }
  };

  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      {/* Hero Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto text-center">
          <h1 className="text-5xl md:text-6xl font-bold mb-6">{streamConfig.stationName}</h1>
          <p className="text-xl md:text-2xl mb-10">{streamConfig.stationSlogan}</p>
          
          <button 
            onClick={handlePlayClick}
            className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-4 px-8 rounded-full text-xl transition-all transform hover:scale-105 flex items-center justify-center mx-auto"
          >
            {isPlaying ? (
              <>
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Pause Stream
              </>
            ) : (
              <>
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Listen Live
              </>
            )}
          </button>
        </div>
      </section>

      {/* Featured Content */}
      <section className="py-12 px-4 bg-black/30">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold mb-8 text-center">Featured Content</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Featured Artists */}
            <div className="bg-gradient-to-br from-purple-800 to-purple-900 rounded-lg p-6 shadow-lg transform transition-all hover:-translate-y-1">
              <h3 className="text-2xl font-bold mb-4">Featured Artists</h3>
              <p className="mb-4">Discover the talented artists featured on our station.</p>
              <a href="/artists" className="text-purple-300 hover:text-white font-semibold inline-flex items-center">
                Explore Artists
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 ml-1" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
              </a>
            </div>

            {/* Featured Podcasts */}
            <div className="bg-gradient-to-br from-indigo-800 to-indigo-900 rounded-lg p-6 shadow-lg transform transition-all hover:-translate-y-1">
              <h3 className="text-2xl font-bold mb-4">Latest Podcasts</h3>
              <p className="mb-4">Tune in to our original podcast series and classic shows.</p>
              <a href="/podcasts" className="text-indigo-300 hover:text-white font-semibold inline-flex items-center">
                Listen to Podcasts
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 ml-1" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
              </a>
            </div>

            {/* Blog Posts */}
            <div className="bg-gradient-to-br from-blue-800 to-blue-900 rounded-lg p-6 shadow-lg transform transition-all hover:-translate-y-1">
              <h3 className="text-2xl font-bold mb-4">Latest Blog Posts</h3>
              <p className="mb-4">Read the latest news, interviews, and updates from our team.</p>
              <a href="/blog" className="text-blue-300 hover:text-white font-semibold inline-flex items-center">
                Read our Blog
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 ml-1" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* About Section */}
      <section className="py-16 px-4">
        <div className="container mx-auto">
          <div className="max-w-3xl mx-auto text-center">
            <h2 className="text-3xl font-bold mb-6">About {streamConfig.stationName}</h2>
            <p className="text-lg mb-6">
              Welcome to ItsYourRadio, your destination for the best music, podcasts, and audio content.
              We're passionate about bringing you quality programming and showcasing talented artists from around the world.
            </p>
            <p className="text-lg">
              Our station features a diverse range of genres, original podcast series, and exclusive content.
              Become a member today to access more features and support our growing community!
            </p>
          </div>
        </div>
      </section>

      {/* Call-to-Action */}
      <section className="py-12 px-4 bg-purple-900">
        <div className="container mx-auto text-center">
          <h2 className="text-3xl font-bold mb-4">Join Our Community</h2>
          <p className="text-xl mb-8">Sign up today to become a member and unlock exclusive features!</p>
          <a 
            href="/register" 
            className="bg-white text-purple-900 hover:bg-gray-100 font-bold py-3 px-8 rounded-full text-lg transition-all transform hover:scale-105 inline-block"
          >
            Sign Up Now
          </a>
        </div>
      </section>

      {/* Spacing to account for the fixed player */}
      <div className="h-24"></div>
    </div>
  );
};

export default Home;
