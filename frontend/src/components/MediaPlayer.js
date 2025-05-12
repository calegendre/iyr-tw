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
  } = useContext(AudioPlayerContext);

  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const progressRef = useRef(null);

  // Format time in MM:SS
  const formatTime = (seconds) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return `${minutes}:${remainingSeconds < 10 ? "0" : ""}${remainingSeconds}`;
  };

  // Set up audio element and listeners
  useEffect(() => {
    if (!audioRef.current) {
      audioRef.current = new Audio();
      audioRef.current.volume = volume / 100;
    }

    const setAudioData = () => {
      setDuration(audioRef.current.duration);
    };

    const setAudioProgress = () => {
      setCurrentTime(audioRef.current.currentTime);
      setProgress((audioRef.current.currentTime / audioRef.current.duration) * 100);
    };

    const onEnded = () => {
      setProgress(0);
      setCurrentTime(0);
      pauseTrack();
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
  }, [audioRef, pauseTrack, volume]);

  // Update when track changes
  useEffect(() => {
    if (currentTrack && audioRef.current) {
      audioRef.current.src = currentTrack.audioUrl;
      audioRef.current.load();
      if (isPlaying) {
        audioRef.current.play();
      }
    }
  }, [currentTrack, isPlaying, audioRef]);

  // Handle play/pause
  useEffect(() => {
    if (audioRef.current) {
      if (isPlaying) {
        audioRef.current.play();
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
    const newProgress = e.target.value;
    setProgress(newProgress);
    audioRef.current.currentTime = (newProgress / 100) * duration;
  };

  if (!currentTrack) return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gray-800 text-white p-2 z-50">
      <div className="container mx-auto flex flex-col md:flex-row items-center justify-between px-4">
        <div className="flex items-center w-full md:w-auto mb-2 md:mb-0">
          {currentTrack.coverImage && (
            <img
              src={currentTrack.coverImage}
              alt={currentTrack.title}
              className="w-12 h-12 mr-4 rounded"
            />
          )}
          <div className="truncate">
            <div className="font-semibold truncate">{currentTrack.title}</div>
            <div className="text-sm text-gray-400 truncate">{currentTrack.artist}</div>
          </div>
        </div>

        <div className="flex flex-col w-full md:w-1/2">
          <div className="flex items-center justify-center mb-1">
            <button
              onClick={isPlaying ? pauseTrack : resumeTrack}
              className="p-2 mx-4 rounded-full bg-white text-gray-800 focus:outline-none hover:bg-gray-200"
              aria-label={isPlaying ? "Pause" : "Play"}
            >
              {isPlaying ? "⏸" : "▶️"}
            </button>
          </div>

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
        </div>

        <div className="flex items-center mt-2 md:mt-0">
          <span className="mr-2 text-xs">
            {volume > 0 ? "🔊" : "🔇"}
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