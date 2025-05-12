import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';

const Blog = () => {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchPosts = async () => {
      try {
        const response = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/api/blog`);
        setPosts(response.data);
      } catch (err) {
        console.error('Error fetching blog posts:', err);
        setError('Failed to load blog posts. Please try again later.');
        
        // For demo purposes, add some sample posts
        setPosts([
          {
            id: '1',
            title: 'New Music Friday: Top Releases This Week',
            content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus ac magna non augue porttitor scelerisque ac id diam...',
            author_id: '101',
            featured_image_url: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
            published_at: '2023-06-15T10:00:00Z',
            author: {
              username: 'musiceditor',
              full_name: 'Jane Smith'
            }
          },
          {
            id: '2',
            title: 'Interview with Rising Star DJ MAXVS',
            content: 'Nullam at quam ut lacus aliquam tempor vel sed ipsum. Donec pellentesque tincidunt imperdiet. Mauris sit amet justo vulputate...',
            author_id: '102',
            featured_image_url: 'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
            published_at: '2023-06-10T14:30:00Z',
            author: {
              username: 'interviewmaster',
              full_name: 'Robert Johnson'
            }
          },
          {
            id: '3',
            title: 'The Evolution of Electronic Music: From Kraftwerk to Present',
            content: 'Cras finibus convallis enim, at dignissim justo aliquam sed. Etiam augue massa, consequat id commodo in, pretium et velit...',
            author_id: '103',
            featured_image_url: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
            published_at: '2023-06-05T09:45:00Z',
            author: {
              username: 'musichistorian',
              full_name: 'Alex Thompson'
            }
          }
        ]);
      } finally {
        setLoading(false);
      }
    };

    fetchPosts();
  }, []);

  const formatDate = (dateString) => {
    const options = { year: 'numeric', month: 'long', day: 'numeric' };
    return new Date(dateString).toLocaleDateString(undefined, options);
  };

  if (loading) {
    return (
      <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
        <div className="container mx-auto px-4 py-16">
          <h1 className="text-4xl font-bold mb-8 text-center">Blog</h1>
          <div className="flex justify-center">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-500"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      <div className="container mx-auto px-4 py-16">
        <h1 className="text-4xl font-bold mb-8 text-center">Blog</h1>
        
        {error && (
          <div className="bg-red-500/20 border border-red-500 text-red-100 px-4 py-3 rounded mb-6 max-w-3xl mx-auto">
            {error}
          </div>
        )}
        
        {posts.length > 0 ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 max-w-6xl mx-auto">
            {/* Featured post (first post) */}
            <div className="lg:col-span-2">
              <Link 
                to={`/blog/${posts[0].id}`}
                className="block bg-gray-800 rounded-lg overflow-hidden shadow-lg hover:shadow-xl transition group"
              >
                <div className="h-96 bg-gray-700 overflow-hidden">
                  <img 
                    src={posts[0].featured_image_url || 'https://via.placeholder.com/1200x800?text=Featured+Post'} 
                    alt={posts[0].title}
                    className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-300"
                  />
                </div>
                <div className="p-8">
                  <div className="flex items-center justify-between mb-4">
                    <span className="bg-purple-600 text-white text-sm px-3 py-1 rounded-full">
                      Featured
                    </span>
                    <span className="text-gray-400">
                      {formatDate(posts[0].published_at)}
                    </span>
                  </div>
                  <h2 className="text-2xl font-bold mb-4 group-hover:text-purple-400 transition">
                    {posts[0].title}
                  </h2>
                  <p className="text-gray-300 mb-6 line-clamp-3">
                    {posts[0].content.substring(0, 200)}...
                  </p>
                  <div className="flex items-center">
                    <span className="text-purple-400">Read More</span>
                    <svg 
                      xmlns="http://www.w3.org/2000/svg" 
                      className="h-5 w-5 ml-1 text-purple-400" 
                      viewBox="0 0 20 20" 
                      fill="currentColor"
                    >
                      <path 
                        fillRule="evenodd" 
                        d="M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z" 
                        clipRule="evenodd" 
                      />
                    </svg>
                  </div>
                </div>
              </Link>
            </div>
            
            {/* Rest of the posts */}
            {posts.slice(1).map((post) => (
              <Link 
                key={post.id}
                to={`/blog/${post.id}`}
                className="block bg-gray-800 rounded-lg overflow-hidden shadow-lg hover:shadow-xl transition group"
              >
                <div className="h-64 bg-gray-700 overflow-hidden">
                  <img 
                    src={post.featured_image_url || 'https://via.placeholder.com/800x600?text=Blog+Post'} 
                    alt={post.title}
                    className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-300"
                  />
                </div>
                <div className="p-6">
                  <div className="flex justify-between mb-2">
                    <span className="text-sm text-gray-400">
                      By {post.author?.full_name || post.author?.username || 'Unknown Author'}
                    </span>
                    <span className="text-sm text-gray-400">
                      {formatDate(post.published_at)}
                    </span>
                  </div>
                  <h2 className="text-xl font-bold mb-3 group-hover:text-purple-400 transition">
                    {post.title}
                  </h2>
                  <p className="text-gray-300 mb-4 line-clamp-2">
                    {post.content.substring(0, 120)}...
                  </p>
                  <div className="flex items-center">
                    <span className="text-purple-400 text-sm">Read More</span>
                    <svg 
                      xmlns="http://www.w3.org/2000/svg" 
                      className="h-4 w-4 ml-1 text-purple-400" 
                      viewBox="0 0 20 20" 
                      fill="currentColor"
                    >
                      <path 
                        fillRule="evenodd" 
                        d="M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z" 
                        clipRule="evenodd" 
                      />
                    </svg>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        ) : (
          <div className="text-center text-gray-400">
            <p className="text-xl">No blog posts available.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Blog;
