# Stream Configuration Guide

## Setting Up Your Radio Stream

To connect your radio station stream to the website, edit the values in `streamConfig.js`:

### Required Configuration

1. **stationStreamUrl**: Your primary Shoutcast/Icecast stream URL
   - Example: `"https://yourstreamserver.com:8000/stream"`
   - This is where your live radio stream is hosted

2. **streamFormat**: The audio format of your stream
   - Common formats: `"audio/mpeg"` (MP3), `"audio/aac"`, `"audio/ogg"`
   - Must match your actual stream format

### Optional Configuration

- **metadataUrl**: If your metadata is served separately from your main stream
- **fallbackStreamUrl**: A backup stream to use if the main one fails
- **stationName** and **stationSlogan**: Your branding information
- **defaultArtwork**: Path to default album art when none is provided

### Advanced Settings

- **bufferingTime**: How many seconds to buffer before playing (affects startup delay)
- **autoReconnect**: Whether to automatically try reconnecting if the stream drops
- **maxRetryAttempts** and **retryDelayMs**: Controls reconnection behavior

## Shoutcast/Icecast Server Setup

If you're setting up your own streaming server:

1. For Shoutcast:
   - Default port is 8000
   - Stream URL format: `http://yourserver.com:8000/;stream.nsv`

2. For Icecast:
   - Default port is 8000
   - Stream URL format: `http://yourserver.com:8000/stream`

## Testing Your Stream

Once configured, your stream will automatically load when visitors access the website. The persistent player will appear at the bottom of every page.
