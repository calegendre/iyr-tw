# Asset Placement Instructions for itsyourradio

## PWA Icons

Place the following icon files in the `/public_html/icons/` directory:

- `icon-72x72.png` (72x72 pixels)
- `icon-96x96.png` (96x96 pixels)
- `icon-128x128.png` (128x128 pixels)
- `icon-144x144.png` (144x144 pixels)
- `icon-152x152.png` (152x152 pixels)
- `icon-192x192.png` (192x192 pixels)
- `icon-384x384.png` (384x384 pixels)
- `icon-512x512.png` (512x512 pixels)
- `splash-screen.png` (1242x2688 pixels - for iOS splash screen)

All icons should be in PNG format with a transparent background. The design should be consistent across all sizes, with the itsyourradio logo centered.

## Logo Files

Place the following logo files in the `/public_html/` directory:

- `logo.png` - Primary logo (used in the header)
- `favicon.ico` - Website favicon (16x16, 32x32, and 48x48 combined)
- `logo-dark.png` - Dark version of logo (used in emails and light backgrounds)
- `default-album-art.jpg` - Default album art when none is provided (500x500 pixels)

## Media Storage Folders

The following directories will be automatically created for storing uploaded content:

- `/public_html/uploads/profile_images/` - User profile images
- `/public_html/uploads/cover_images/` - Cover images for artists and profiles
- `/public_html/uploads/album_art/` - Album artwork
- `/public_html/uploads/podcast_covers/` - Podcast show artwork
- `/public_html/station/music/` - Uploaded music files (organized by artist/album)
- `/public_html/station/podcasts/` - Uploaded podcast episodes

## Configuration Files

To configure your Shoutcast/Icecast stream URL:

1. Navigate to `/public_html/static/js/` folder
2. Find the file containing `streamConfig` (exact filename will vary with each build)
3. Modify the `stationStreamUrl` value to your stream URL
4. Save the file

Alternatively, you can update `/app/frontend/src/config/streamConfig.js` before building the application.

## Customizing Station Information

You can customize the station information in the same file as the stream URL:

- `stationName` - Your station's name
- `stationSlogan` - Your station's slogan
- `defaultArtwork` - Path to default artwork
- `defaultVolume` - Default volume level (0.0 to 1.0)

## Default Admin Account

The default admin account credentials are:

- Email: admin@itsyourradio.com
- Password: IYR_admin_2025!

**Important:** Change these credentials immediately after your first login for security purposes.
