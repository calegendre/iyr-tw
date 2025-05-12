import React, { useState, useRef, useEffect } from 'react';
import { useMediaPlayer } from '../../contexts/MediaPlayerContext';
import streamConfig from '../../config/streamConfig';

// Utility function to format time (e.g., 3:45)
const formatTime = (seconds) => {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = Math.floor(seconds % 60);
  return `${minutes}:${remainingSeconds < 10 ? '0' : ''}${remainingSeconds}`;
};

const MediaPlayer = () => {
  const audioRef = useRef(null);
  const animationRef = useRef(null);
  const [gradientColors, setGradientColors] = useState(['#8a2be2', '#4b0082']);
  const [isBuffering, setIsBuffering] = useState(false);
  
  const { 
    isPlaying, 
    setIsPlaying,
    currentMedia,
    volume, 
    setVolume,
    currentTime,
    setCurrentTime,
    duration,
    setDuration,
    mediaType,
    setMediaType,
    nowPlaying,
    setNowPlaying
  } = useMediaPlayer();

  // Set up audio element and event listeners
  useEffect(() => {
    const audio = audioRef.current;
    
    const onLoadedMetadata = () => {
      setDuration(audio.duration);
      setIsBuffering(false);
    };
    
    const onTimeUpdate = () => {
      setCurrentTime(audio.currentTime);
    };
    
    const onEnded = () => {
      // If it's a podcast or other media, we might want to do something else
      if (mediaType === 'radio') {
        // For radio stream, just keep playing
        audio.currentTime = 0;
        audio.play();
      } else {
        setIsPlaying(false);
        setCurrentTime(0);
      }
    };
    
    const onPlay = () => {
      setIsPlaying(true);
    };
    
    const onPause = () => {
      setIsPlaying(false);
    };
    
    const onWaiting = () => {
      setIsBuffering(true);
    };
    
    const onCanPlay = () => {
      setIsBuffering(false);
    };

    // Add event listeners
    audio.addEventListener('loadedmetadata', onLoadedMetadata);
    audio.addEventListener('timeupdate', onTimeUpdate);
    audio.addEventListener('ended', onEnded);
    audio.addEventListener('play', onPlay);
    audio.addEventListener('pause', onPause);
    audio.addEventListener('waiting', onWaiting);
    audio.addEventListener('canplay', onCanPlay);
    
    // Set initial volume
    audio.volume = volume;
    
    // Clean up event listeners on unmount
    return () => {
      audio.removeEventListener('loadedmetadata', onLoadedMetadata);
      audio.removeEventListener('timeupdate', onTimeUpdate);
      audio.removeEventListener('ended', onEnded);
      audio.removeEventListener('play', onPlay);
      audio.removeEventListener('pause', onPause);
      audio.removeEventListener('waiting', onWaiting);
      audio.removeEventListener('canplay', onCanPlay);
    };
  }, []);

  // Handle media source changes
  useEffect(() => {
    if (currentMedia) {
      setIsBuffering(true);
      
      // For radio, we set duration to Infinity
      if (mediaType === 'radio') {
        setDuration(Infinity);
      }
      
      // Load and play the new source
      if (isPlaying) {
        audioRef.current.load();
        audioRef.current.play().catch(error => {
          console.error("Playback failed:", error);
          setIsPlaying(false);
        });
      }
    }
  }, [currentMedia]);

  // Handle play/pause state changes
  useEffect(() => {
    if (isPlaying) {
      audioRef.current.play().catch(error => {
        console.error("Playback failed:", error);
        setIsPlaying(false);
      });
    } else {
      audioRef.current.pause();
    }
  }, [isPlaying]);

  // Handle volume changes
  useEffect(() => {
    audioRef.current.volume = volume;
  }, [volume]);

  // Set up interval to simulate changing album art colors for visual effect
  useEffect(() => {
    const changeGradient = () => {
      // Generate random colors based on current art or theme
      // For now, we'll just rotate between a few preset color pairs
      const colorPairs = [
        ['#8a2be2', '#4b0082'], // Purple gradient
        ['#ff0000', '#8b0000'], // Red gradient
        ['#1e90ff', '#00008b'], // Blue gradient
        ['#32cd32', '#006400'], // Green gradient
        ['#ffa500', '#ff4500']  // Orange gradient
      ];
      
      const randomPair = colorPairs[Math.floor(Math.random() * colorPairs.length)];
      setGradientColors(randomPair);
    };
    
    // Only animate gradient if playing radio
    if (isPlaying && mediaType === 'radio') {
      const intervalId = setInterval(changeGradient, 5000);
      return () => clearInterval(intervalId);
    }
  }, [isPlaying, mediaType]);

  // Function to handle play/pause toggle
  const togglePlayPause = () => {
    setIsPlaying(!isPlaying);
  };

  // Function to handle volume change
  const handleVolumeChange = (e) => {
    const newVolume = parseFloat(e.target.value);
    setVolume(newVolume);
  };

  // Function to handle seeking
  const handleSeek = (e) => {
    const seekTime = parseFloat(e.target.value);
    audioRef.current.currentTime = seekTime;
    setCurrentTime(seekTime);
  };

  // Function to switch back to radio
  const switchToRadio = () => {
    setMediaType('radio');
    setNowPlaying({
      title: 'Live Radio',
      artist: streamConfig.stationName,
      coverArt: streamConfig.defaultArtwork
    });
    setCurrentMedia(streamConfig.stationStreamUrl);
    setIsPlaying(true);
  };

  return (
    <div 
      className={`fixed bottom-0 left-0 right-0 z-40 transition-all duration-500 ${
        isPlaying 
          ? `bg-gradient-to-r from-${gradientColors[0]} to-${gradientColors[1]}` 
          : 'bg-gray-900'
      } text-white py-2 px-4 shadow-lg`}
    >
      <audio ref={audioRef} preload="auto">
        <source src={currentMedia} type={mediaType === 'radio' ? streamConfig.streamFormat : 'audio/mpeg'} />
        Your browser does not support the audio element.
      </audio>
      
      <div className="container mx-auto flex flex-col sm:flex-row items-center">
        {/* Album Art & Info */}
        <div className="flex items-center mb-2 sm:mb-0 sm:w-1/4">
          <img 
            src={nowPlaying.coverArt || streamConfig.defaultArtwork} 
            alt="Album Art" 
            className="h-12 w-12 rounded-sm mr-3 shadow-lg"
          />
          <div className="truncate">
            <div className="font-semibold truncate">{nowPlaying.title || 'Unknown'}</div>
            <div className="text-sm text-gray-200 truncate">{nowPlaying.artist || 'Unknown Artist'}</div>
          </div>
        </div>
        
        {/* Controls & Progress */}
        <div className="flex flex-col sm:w-2/4 px-4">
          <div className="flex items-center justify-center space-x-4">
            {/* Stop Button (for radio) */}
            {mediaType === 'radio' && (
              <button 
                className="p-2 rounded-full hover:bg-white/10 transition"
                onClick={() => {
                  setIsPlaying(false);
                  // For radio, stop means reset the stream completely
                  audioRef.current.src = streamConfig.stationStreamUrl;
                  audioRef.current.load();
                }}
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <rect x="6" y="6" width="12" height="12" />
                </svg>
              </button>
            )}
            
            {/* Play/Pause Button */}
            <button 
              className="p-2 rounded-full hover:bg-white/10 transition"
              onClick={togglePlayPause}
              disabled={isBuffering}
            >
              {isBuffering ? (
                <svg className="animate-spin h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              ) : isPlaying ? (
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              ) : (
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              )}
            </button>
            
            {/* Switch to Radio Button (when playing other media) */}
            {mediaType !== 'radio' && (
              <button 
                className="p-2 rounded-full hover:bg-white/10 transition"
                onClick={switchToRadio}
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
                <span className="sr-only">Listen to IYR</span>
              </button>
            )}
          </div>
          
          {/* Progress Bar (not shown for radio) */}
          {mediaType !== 'radio' && duration !== Infinity && (
            <div className="flex items-center mt-1">
              <span className="text-xs mr-2">{formatTime(currentTime)}</span>
              <input
                type="range"
                min="0"
                max={duration || 0}
                value={currentTime}
                onChange={handleSeek}
                className="w-full h-1 bg-white/20 rounded-lg appearance-none cursor-pointer"
              />
              <span className="text-xs ml-2">{formatTime(duration)}</span>
            </div>
          )}
        </div>
        
        {/* Volume Control */}
        <div className="flex items-center sm:w-1/4 justify-end">
          <div className="flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              {volume === 0 ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
              ) : volume < 0.5 ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
              )}
            </svg>
            <input
              type="range"
              min="0"
              max="1"
              step="0.01"
              value={volume}
              onChange={handleVolumeChange}
              className="w-20 h-1 bg-white/20 rounded-lg appearance-none cursor-pointer"
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default MediaPlayer;
