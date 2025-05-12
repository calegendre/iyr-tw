/**
 * Radio Station Stream Configuration
 * 
 * This file contains configuration settings for the radio station stream.
 * Update these values to connect to your Shoutcast/Icecast server.
 */

const streamConfig = {
  // Main station stream URL (Shoutcast/Icecast)
  stationStreamUrl: "https://example.com:8000/stream",
  
  // Stream metadata URL (if different from main stream)
  metadataUrl: "https://example.com:8000/metadata",
  
  // Stream format (e.g., "audio/mpeg", "audio/aac", etc.)
  streamFormat: "audio/mpeg",
  
  // Station details
  stationName: "itsyourradio",
  stationSlogan: "Your Music, Your Way",
  
  // Default artwork to display when no album art is available
  defaultArtwork: "/images/default-album-art.jpg",
  
  // Stream fallback URL (used if main stream is unavailable)
  fallbackStreamUrl: "https://backup.example.com:8000/stream",
  
  // Connection retry settings
  maxRetryAttempts: 5,
  retryDelayMs: 3000,
  
  // Advanced settings
  bufferingTime: 2, // seconds
  crossfadeTime: 0.5, // seconds (for transitions between stream and podcasts)
  
  // Volume settings
  defaultVolume: 0.8, // 0.0 to 1.0
  
  // Whether to attempt to reconnect automatically if stream connection is lost
  autoReconnect: true,
};

export default streamConfig;
