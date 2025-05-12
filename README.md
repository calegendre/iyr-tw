# itsyourradio - Radio Station Website

A comprehensive radio station website with streaming, podcasts, artist profiles, and blog features.

## Features

- **Persistent Media Player**: Continues playing while browsing the site
- **Multi-Role User System**: Admin, staff, artist, podcaster, and member roles
- **Artist Profiles**: Showcases artists with discography and blog posts
- **Podcast Management**: Supports shows, episodes, and RSS feeds for Apple Podcasts
- **Blog System**: Main blog and artist mini-blogs
- **Responsive Design**: Mobile-friendly with PWA support
- **Role-Based Dashboards**: Different interfaces for each user role

## Technology Stack

- **Frontend**: React, React Router, Tailwind CSS
- **Backend**: FastAPI (Python)
- **Database**: MySQL/MariaDB
- **Authentication**: JWT-based authentication
- **Media Streaming**: Supports Shoutcast/Icecast integration

## Getting Started

Please follow the detailed instructions in [DEPLOYMENT_INSTRUCTIONS.md](DEPLOYMENT_INSTRUCTIONS.md) to deploy the application on your HestiaCP-based server.

## Default Admin Credentials

- Email: admin@itsyourradio.com
- Password: IYR_admin_2025!

**Important**: Change these credentials immediately after your first login.

## Custom Assets

Instructions for placing your custom logos and assets can be found in the [README-ASSETS.md](frontend/public/README-ASSETS.md) file.

## Stream Configuration

To configure your Shoutcast/Icecast stream URL:

1. Update the `streamConfig.js` file in the frontend build
2. Set your station details, stream URL, and other preferences

## License

This software is provided for the exclusive use of itsyourradio. Unauthorized distribution or use is prohibited.
