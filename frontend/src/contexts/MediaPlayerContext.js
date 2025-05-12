import React, { createContext, useContext, useState, useEffect } from 'react';
import streamConfig from '../config/streamConfig';

// Create context
const MediaPlayerContext = createContext();

// Custom hook to use the media player context
export const useMediaPlayer = () => useContext(MediaPlayerContext);

// Provider component
export const MediaPlayerProvider = ({ children }) => {
  // State for the media player
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentMedia, setCurrentMedia] = useState(streamConfig.stationStreamUrl);
  const [volume, setVolume] = useState(streamConfig.defaultVolume);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [mediaType, setMediaType] = useState('radio'); // 'radio', 'podcast', or 'song'
  const [nowPlaying, setNowPlaying] = useState({
    title: 'Live Radio',
    artist: streamConfig.stationName,
    coverArt: streamConfig.defaultArtwork
  });
  
  // Metadata polling for radio stream
  useEffect(() => {
    let metadataInterval;
    
    const fetchMetadata = async () => {
      // This is a placeholder. In a real implementation, you would fetch metadata
      // from your Shoutcast/Icecast server's metadata endpoint.
      // For now, we'll simulate changing metadata every 30 seconds.
      
      // Note: A real implementation would use the Shoutcast/Icecast metadata API
      try {
        // Simulating API call for now
        // const response = await fetch(streamConfig.metadataUrl);
        // const data = await response.json();
        
        // Simulated data
        const tracks = [
          {
            title: 'Midnight Drive',
            artist: 'SynthWave Collective',
            coverArt: 'https://example.com/cover1.jpg'
          },
          {
            title: 'Summer Dreams',
            artist: 'Coastal Vibes',
            coverArt: 'https://example.com/cover2.jpg'
          },
          {
            title: 'Urban Rhythm',
            artist: 'City Sounds',
            coverArt: 'https://example.com/cover3.jpg'
          }
        ];
        
        const randomTrack = tracks[Math.floor(Math.random() * tracks.length)];
        
        // Only update if we're in radio mode
        if (mediaType === 'radio') {
          setNowPlaying({
            title: randomTrack.title,
            artist: randomTrack.artist,
            coverArt: randomTrack.coverArt || streamConfig.defaultArtwork
          });
        }
      } catch (error) {
        console.error('Failed to fetch metadata:', error);
      }
    };
    
    // Only poll for metadata if playing radio
    if (isPlaying && mediaType === 'radio') {
      // Initial fetch
      fetchMetadata();
      
      // Set up interval for polling
      metadataInterval = setInterval(fetchMetadata, 30000);
    }
    
    return () => {
      if (metadataInterval) {
        clearInterval(metadataInterval);
      }
    };
  }, [isPlaying, mediaType]);
  
  // Play a podcast
  const playPodcast = (podcastData) => {
    setMediaType('podcast');
    setCurrentMedia(podcastData.fileUrl);
    setNowPlaying({
      title: podcastData.title,
      artist: podcastData.host,
      coverArt: podcastData.coverArt
    });
    setIsPlaying(true);
    setCurrentTime(0);
  };
  
  // Play a song
  const playSong = (songData) => {
    setMediaType('song');
    setCurrentMedia(songData.fileUrl);
    setNowPlaying({
      title: songData.title,
      artist: songData.artist,
      coverArt: songData.coverArt
    });
    setIsPlaying(true);
    setCurrentTime(0);
  };
  
  // Return to live radio
  const playLiveRadio = () => {
    setMediaType('radio');
    setCurrentMedia(streamConfig.stationStreamUrl);
    setNowPlaying({
      title: 'Live Radio',
      artist: streamConfig.stationName,
      coverArt: streamConfig.defaultArtwork
    });
    setIsPlaying(true);
  };
  
  // Value to be provided by the context
  const value = {
    isPlaying,
    setIsPlaying,
    currentMedia,
    setCurrentMedia,
    volume,
    setVolume,
    currentTime,
    setCurrentTime,
    duration,
    setDuration,
    mediaType,
    setMediaType,
    nowPlaying,
    setNowPlaying,
    playPodcast,
    playSong,
    playLiveRadio
  };

  return (
    <MediaPlayerContext.Provider value={value}>
      {children}
    </MediaPlayerContext.Provider>
  );
};
