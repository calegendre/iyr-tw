export const mockArtists = [
  {
    id: "1",
    name: "TNGHT",
    genre: "Electronic",
    image: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    bio: "TNGHT is a collaborative project between producers Hudson Mohawke and Lunice."
  },
  {
    id: "2",
    name: "Portishead",
    genre: "Trip Hop",
    image: "https://images.unsplash.com/photo-1528489290189-1174a4c24021?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60", 
    bio: "Portishead are an English band formed in 1991 in Bristol."
  },
  {
    id: "3",
    name: "Massive Attack",
    genre: "Trip Hop",
    image: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    bio: "Massive Attack are a British musical collective formed in 1988 in Bristol."
  },
  {
    id: "4",
    name: "Bonobo",
    genre: "Electronic",
    image: "https://images.unsplash.com/photo-1554474252-e6956231dd4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGVsZWN0cm9uaWMlMjBtdXNpY3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    bio: "Bonobo is the stage name of British musician, producer and DJ Simon Green."
  }
];

export const mockTracks = [
  {
    id: "101",
    title: "Higher Ground",
    artist: "TNGHT",
    artistId: "1",
    albumId: "201",
    coverImage: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/tnght/higher-ground",
    duration: 182
  },
  {
    id: "102",
    title: "Glory Box",
    artist: "Portishead",
    artistId: "2",
    albumId: "202",
    coverImage: "https://images.unsplash.com/photo-1528489290189-1174a4c24021?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/portishead/glory-box",
    duration: 300
  },
  {
    id: "103",
    title: "Teardrop",
    artist: "Massive Attack",
    artistId: "3",
    albumId: "203",
    coverImage: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/massiveattack/teardrop",
    duration: 330
  },
  {
    id: "104",
    title: "Kerala",
    artist: "Bonobo",
    artistId: "4",
    albumId: "204",
    coverImage: "https://images.unsplash.com/photo-1554474252-e6956231dd4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGVsZWN0cm9uaWMlMjBtdXNpY3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/bonobo/kerala",
    duration: 245
  }
];

export const mockAlbums = [
  {
    id: "201",
    title: "TNGHT EP",
    artist: "TNGHT",
    artistId: "1",
    coverImage: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    releaseDate: "2012-07-23",
    trackIds: ["101"]
  },
  {
    id: "202",
    title: "Dummy",
    artist: "Portishead",
    artistId: "2",
    coverImage: "https://images.unsplash.com/photo-1528489290189-1174a4c24021?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    releaseDate: "1994-08-22",
    trackIds: ["102"]
  },
  {
    id: "203",
    title: "Mezzanine",
    artist: "Massive Attack",
    artistId: "3",
    coverImage: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    releaseDate: "1998-04-20",
    trackIds: ["103"]
  },
  {
    id: "204",
    title: "Migration",
    artist: "Bonobo",
    artistId: "4",
    coverImage: "https://images.unsplash.com/photo-1554474252-e6956231dd4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGVsZWN0cm9uaWMlMjBtdXNpY3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    releaseDate: "2017-01-13",
    trackIds: ["104"]
  }
];

export const mockPodcasts = [
  {
    id: "301",
    title: "Radio Stories",
    host: "Sarah Johnson",
    coverImage: "https://images.unsplash.com/photo-1524254994761-171214f567f3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8cG9kY2FzdHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    description: "Exploring the stories behind the music and the radio industry.",
    latestEpisode: {
      title: "The Future of Radio",
      publishedAt: "2023-04-15"
    }
  },
  {
    id: "302",
    title: "Music Theory",
    host: "David Wilson",
    coverImage: "https://images.unsplash.com/photo-1551817272-cad54b74b273?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8bXVzaWMlMjB0aGVvcnl8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
    description: "Exploring music theory concepts for musicians at all levels.",
    latestEpisode: {
      title: "Understanding Modal Interchange",
      publishedAt: "2023-04-10"
    }
  },
  {
    id: "303",
    title: "Artist Interviews",
    host: "Maya Rodriguez",
    coverImage: "https://images.unsplash.com/photo-1547156979-b57c6439f174?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aW50ZXJ2aWV3fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    description: "In-depth interviews with artists about their creative process.",
    latestEpisode: {
      title: "The Creative Process with TNGHT",
      publishedAt: "2023-04-05"
    }
  }
];

export const mockBlogPosts = [
  {
    id: "401",
    title: "The Evolution of Electronic Music",
    author: "Admin",
    authorId: "admin",
    publishedAt: "2023-04-01",
    featuredImage: "https://images.unsplash.com/photo-1571330735066-03aaa9429d89?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    excerpt: "Exploring how electronic music has evolved over the decades and its influence on popular culture.",
    content: "Electronic music has come a long way since the early experiments with synthesizers and tape loops..."
  },
  {
    id: "402",
    title: "The Rise of Indie Radio",
    author: "Sarah Johnson",
    authorId: "sarah",
    publishedAt: "2023-03-25",
    featuredImage: "https://images.unsplash.com/photo-1589398907430-a7b688975b6c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cmFkaW98ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
    excerpt: "How independent radio stations are making a comeback in the age of streaming.",
    content: "In an era dominated by streaming platforms, independent radio stations are experiencing a renaissance..."
  },
  {
    id: "403",
    title: "Behind the Scenes: Podcast Production",
    author: "David Wilson",
    authorId: "david",
    publishedAt: "2023-03-20",
    featuredImage: "https://images.unsplash.com/photo-1590602847861-f357a9332bbc?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fHBvZGNhc3R8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
    excerpt: "A look at what goes into producing a professional podcast.",
    content: "Creating a successful podcast involves much more than just recording a conversation..."
  }
];