import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const AdminDashboard = () => {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('users');
  const [menuItems, setMenuItems] = useState([
    { id: 1, label: 'Home', url: '/', order: 1, isActive: true },
    { id: 2, label: 'Artists', url: '/artists', order: 2, isActive: true },
    { id: 3, label: 'Podcasts', url: '/podcasts', order: 3, isActive: true },
    { id: 4, label: 'Blog', url: '/blog', order: 4, isActive: true },
    { id: 5, label: 'Contact', url: '/contact', order: 5, isActive: false }
  ]);
  
  // Mock data for users
  const [users, setUsers] = useState([
    {
      id: '1',
      username: 'johndoe',
      email: 'john@example.com',
      full_name: 'John Doe',
      role: 'admin',
      created_at: '2023-01-15T10:30:00Z'
    },
    {
      id: '2',
      username: 'janedoe',
      email: 'jane@example.com',
      full_name: 'Jane Doe',
      role: 'staff',
      created_at: '2023-01-20T14:45:00Z'
    },
    {
      id: '3',
      username: 'rockstar',
      email: 'rock@example.com',
      full_name: 'Rock Star',
      role: 'artist',
      created_at: '2023-02-05T09:15:00Z'
    },
    {
      id: '4',
      username: 'podhost',
      email: 'pod@example.com',
      full_name: 'Pod Host',
      role: 'podcaster',
      created_at: '2023-02-10T11:20:00Z'
    },
    {
      id: '5',
      username: 'listener',
      email: 'listen@example.com',
      full_name: 'Regular Listener',
      role: 'member',
      created_at: '2023-03-01T16:00:00Z'
    }
  ]);
  
  // Mock data for pages
  const [pages, setPages] = useState([
    {
      id: '1',
      title: 'About Us',
      slug: 'about',
      author_id: '1',
      created_at: '2023-01-20T12:00:00Z',
      is_published: true
    },
    {
      id: '2',
      title: 'Contact Us',
      slug: 'contact',
      author_id: '2',
      created_at: '2023-01-25T14:30:00Z',
      is_published: true
    },
    {
      id: '3',
      title: 'Terms of Service',
      slug: 'terms',
      author_id: '1',
      created_at: '2023-02-10T09:45:00Z',
      is_published: true
    },
    {
      id: '4',
      title: 'Privacy Policy',
      slug: 'privacy',
      author_id: '1',
      created_at: '2023-02-10T10:30:00Z',
      is_published: true
    },
    {
      id: '5',
      title: 'Upcoming Events',
      slug: 'events',
      author_id: '2',
      created_at: '2023-03-05T15:20:00Z',
      is_published: false
    }
  ]);
  
  // Redirect if not logged in or not an admin/staff
  if (loading) {
    return (
      <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-500"></div>
      </div>
    );
  }
  
  if (!user || (user.role !== 'admin' && user.role !== 'staff')) {
    return <Navigate to="/login" />;
  }
  
  // Function to toggle menu item status
  const toggleMenuItemStatus = (id) => {
    setMenuItems(menuItems.map(item => 
      item.id === id ? { ...item, isActive: !item.isActive } : item
    ));
  };
  
  // Function to change menu item order
  const moveMenuItem = (id, direction) => {
    const itemIndex = menuItems.findIndex(item => item.id === id);
    const newMenuItems = [...menuItems];
    
    if (direction === 'up' && itemIndex > 0) {
      // Swap with previous item
      const temp = newMenuItems[itemIndex];
      newMenuItems[itemIndex] = newMenuItems[itemIndex - 1];
      newMenuItems[itemIndex - 1] = temp;
      
      // Update order properties
      newMenuItems[itemIndex].order = itemIndex + 1;
      newMenuItems[itemIndex - 1].order = itemIndex;
    } else if (direction === 'down' && itemIndex < menuItems.length - 1) {
      // Swap with next item
      const temp = newMenuItems[itemIndex];
      newMenuItems[itemIndex] = newMenuItems[itemIndex + 1];
      newMenuItems[itemIndex + 1] = temp;
      
      // Update order properties
      newMenuItems[itemIndex].order = itemIndex + 1;
      newMenuItems[itemIndex + 1].order = itemIndex + 2;
    }
    
    setMenuItems(newMenuItems);
  };
  
  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">Admin Dashboard</h1>
        
        {/* Tabs */}
        <div className="mb-8 border-b border-gray-700">
          <nav className="flex flex-wrap">
            <button
              onClick={() => setActiveTab('users')}
              className={`pb-4 px-4 ${
                activeTab === 'users'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Users
            </button>
            <button
              onClick={() => setActiveTab('pages')}
              className={`pb-4 px-4 ${
                activeTab === 'pages'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Pages
            </button>
            <button
              onClick={() => setActiveTab('menu')}
              className={`pb-4 px-4 ${
                activeTab === 'menu'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Menu Manager
            </button>
            <button
              onClick={() => setActiveTab('settings')}
              className={`pb-4 px-4 ${
                activeTab === 'settings'
                  ? 'border-b-2 border-purple-500 text-purple-400 font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Settings
            </button>
          </nav>
        </div>
        
        {/* Tab Content */}
        <div className="mt-6">
          {/* Users Tab */}
          {activeTab === 'users' && (
            <div className="bg-gray-800 rounded-lg p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold">User Management</h2>
                <button className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors">
                  Add New User
                </button>
              </div>
              
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead className="bg-gray-700">
                    <tr>
                      <th className="py-3 px-4 rounded-tl-md">Username</th>
                      <th className="py-3 px-4">Full Name</th>
                      <th className="py-3 px-4">Email</th>
                      <th className="py-3 px-4">Role</th>
                      <th className="py-3 px-4">Joined</th>
                      <th className="py-3 px-4 rounded-tr-md">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((user, index) => (
                      <tr 
                        key={user.id} 
                        className={index % 2 === 0 ? 'bg-gray-700/50' : 'bg-gray-700/30'}
                      >
                        <td className="py-3 px-4">{user.username}</td>
                        <td className="py-3 px-4">{user.full_name}</td>
                        <td className="py-3 px-4">{user.email}</td>
                        <td className="py-3 px-4">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            user.role === 'admin' 
                              ? 'bg-red-500/20 text-red-300' 
                              : user.role === 'staff'
                                ? 'bg-blue-500/20 text-blue-300'
                                : user.role === 'artist'
                                  ? 'bg-purple-500/20 text-purple-300'
                                  : user.role === 'podcaster'
                                    ? 'bg-green-500/20 text-green-300'
                                    : 'bg-gray-500/20 text-gray-300'
                          }`}>
                            {user.role.charAt(0).toUpperCase() + user.role.slice(1)}
                          </span>
                        </td>
                        <td className="py-3 px-4">{new Date(user.created_at).toLocaleDateString()}</td>
                        <td className="py-3 px-4">
                          <button className="text-purple-400 hover:text-purple-300 transition mr-3">
                            Edit
                          </button>
                          <button className="text-red-400 hover:text-red-300 transition">
                            Delete
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
          
          {/* Pages Tab */}
          {activeTab === 'pages' && (
            <div className="bg-gray-800 rounded-lg p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold">Page Management</h2>
                <button className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors">
                  Create New Page
                </button>
              </div>
              
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead className="bg-gray-700">
                    <tr>
                      <th className="py-3 px-4 rounded-tl-md">Title</th>
                      <th className="py-3 px-4">Slug</th>
                      <th className="py-3 px-4">Created</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4 rounded-tr-md">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pages.map((page, index) => (
                      <tr 
                        key={page.id} 
                        className={index % 2 === 0 ? 'bg-gray-700/50' : 'bg-gray-700/30'}
                      >
                        <td className="py-3 px-4">{page.title}</td>
                        <td className="py-3 px-4">{page.slug}</td>
                        <td className="py-3 px-4">{new Date(page.created_at).toLocaleDateString()}</td>
                        <td className="py-3 px-4">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            page.is_published
                              ? 'bg-green-500/20 text-green-300'
                              : 'bg-yellow-500/20 text-yellow-300'
                          }`}>
                            {page.is_published ? 'Published' : 'Draft'}
                          </span>
                        </td>
                        <td className="py-3 px-4">
                          <button className="text-purple-400 hover:text-purple-300 transition mr-3">
                            Edit
                          </button>
                          <button className="text-blue-400 hover:text-blue-300 transition mr-3">
                            View
                          </button>
                          <button className="text-red-400 hover:text-red-300 transition">
                            Delete
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
          
          {/* Menu Manager Tab */}
          {activeTab === 'menu' && (
            <div>
              <div className="bg-gray-800 rounded-lg p-6 mb-6">
                <h2 className="text-xl font-bold mb-6">Menu Manager</h2>
                <p className="text-gray-300 mb-4">
                  Drag and drop menu items to rearrange them. Toggle the switch to show/hide items in the navigation menu.
                </p>
                
                <ul className="space-y-3 mb-6">
                  {menuItems.sort((a, b) => a.order - b.order).map(item => (
                    <li 
                      key={item.id} 
                      className="bg-gray-700 rounded-lg p-4 flex items-center justify-between"
                    >
                      <div className="flex items-center">
                        <span className="font-medium mr-2">{item.label}</span>
                        <span className="text-gray-400 text-sm">{item.url}</span>
                      </div>
                      <div className="flex items-center space-x-3">
                        <button 
                          onClick={() => moveMenuItem(item.id, 'up')}
                          className="text-gray-400 hover:text-white p-1"
                          disabled={item.order === 1}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                            <path fillRule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clipRule="evenodd" />
                          </svg>
                        </button>
                        <button 
                          onClick={() => moveMenuItem(item.id, 'down')}
                          className="text-gray-400 hover:text-white p-1"
                          disabled={item.order === menuItems.length}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                            <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
                          </svg>
                        </button>
                        <label className="inline-flex items-center cursor-pointer">
                          <input 
                            type="checkbox" 
                            className="sr-only peer"
                            checked={item.isActive}
                            onChange={() => toggleMenuItemStatus(item.id)}
                          />
                          <div className="relative w-11 h-6 bg-gray-600 rounded-full peer peer-checked:bg-purple-600 peer-focus:ring-2 peer-focus:ring-purple-300">
                            <div className="absolute w-4 h-4 bg-white rounded-full left-1 top-1 transition peer-checked:left-6"></div>
                          </div>
                        </label>
                      </div>
                    </li>
                  ))}
                </ul>
                
                <button className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors">
                  Add Menu Item
                </button>
              </div>
              
              <div className="bg-gray-800 rounded-lg p-6">
                <h2 className="text-xl font-bold mb-4">Preview</h2>
                <div className="bg-gray-900 p-4 rounded-lg">
                  <nav className="flex flex-wrap gap-4">
                    {menuItems
                      .filter(item => item.isActive)
                      .sort((a, b) => a.order - b.order)
                      .map(item => (
                        <a 
                          key={item.id}
                          href={item.url}
                          className="text-white hover:text-purple-400 transition"
                        >
                          {item.label}
                        </a>
                      ))
                    }
                  </nav>
                </div>
              </div>
            </div>
          )}
          
          {/* Settings Tab */}
          {activeTab === 'settings' && (
            <div className="bg-gray-800 rounded-lg p-6">
              <h2 className="text-xl font-bold mb-6">Site Settings</h2>
              
              <form className="space-y-6">
                <div>
                  <h3 className="text-lg font-medium mb-4">General Settings</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium mb-1">Site Name</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        defaultValue="ItsYourRadio"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Site Tagline</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        defaultValue="Your Music, Your Way"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Admin Email</label>
                      <input 
                        type="email"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        defaultValue="admin@itsyourradio.com"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Site Language</label>
                      <select className="w-full bg-gray-700 rounded-md py-2 px-4">
                        <option value="en">English</option>
                        <option value="es">Spanish</option>
                        <option value="fr">French</option>
                        <option value="de">German</option>
                      </select>
                    </div>
                  </div>
                </div>
                
                <div className="border-t border-gray-700 pt-6">
                  <h3 className="text-lg font-medium mb-4">Radio Stream Settings</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium mb-1">Stream URL</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        defaultValue="https://example.com:8000/stream"
                      />
                      <p className="text-xs text-gray-400 mt-1">Your Shoutcast/Icecast server URL</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Metadata URL</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        defaultValue="https://example.com:8000/metadata"
                      />
                      <p className="text-xs text-gray-400 mt-1">Optional: URL for stream metadata</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Stream Format</label>
                      <select className="w-full bg-gray-700 rounded-md py-2 px-4">
                        <option value="audio/mpeg">MP3 (audio/mpeg)</option>
                        <option value="audio/aac">AAC (audio/aac)</option>
                        <option value="audio/ogg">OGG (audio/ogg)</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Default Volume</label>
                      <input 
                        type="range"
                        min="0"
                        max="100"
                        defaultValue="80"
                        className="w-full bg-gray-700 rounded-lg appearance-none cursor-pointer"
                      />
                      <div className="flex justify-between">
                        <span className="text-xs text-gray-400">0%</span>
                        <span className="text-xs text-gray-400">100%</span>
                      </div>
                    </div>
                  </div>
                </div>
                
                <div className="border-t border-gray-700 pt-6">
                  <h3 className="text-lg font-medium mb-4">Social Media Links</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium mb-1">Facebook</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        placeholder="https://facebook.com/itsyourradio"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Twitter</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        placeholder="https://twitter.com/itsyourradio"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">Instagram</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        placeholder="https://instagram.com/itsyourradio"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">YouTube</label>
                      <input 
                        type="text"
                        className="w-full bg-gray-700 rounded-md py-2 px-4"
                        placeholder="https://youtube.com/itsyourradio"
                      />
                    </div>
                  </div>
                </div>
                
                <div className="flex justify-end">
                  <button 
                    type="submit"
                    className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors"
                  >
                    Save Settings
                  </button>
                </div>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
