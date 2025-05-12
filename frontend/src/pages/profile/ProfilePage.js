import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import FileUploader from '../../components/upload/FileUploader';

const ProfilePage = () => {
  const { user } = useAuth();
  const [formData, setFormData] = useState({
    fullName: user?.full_name || '',
    bio: user?.bio || '',
    email: user?.email || '',
  });
  const [uploadSuccess, setUploadSuccess] = useState(null);
  const [uploadError, setUploadError] = useState(null);
  const [saveSuccess, setSaveSuccess] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    // In a real app, we would save to backend
    // For now, just show success message
    setSaveSuccess('Profile updated successfully!');
    setTimeout(() => setSaveSuccess(null), 3000);
  };

  const handleUploadSuccess = (data) => {
    setUploadSuccess('Image uploaded successfully!');
    setUploadError(null);
    setTimeout(() => setUploadSuccess(null), 3000);
  };

  const handleUploadError = () => {
    setUploadError('Failed to upload image. Please try again.');
    setUploadSuccess(null);
    setTimeout(() => setUploadError(null), 3000);
  };

  // Check which dashboard link to show based on user role
  const getDashboardLink = () => {
    switch (user?.role) {
      case 'admin':
      case 'staff':
        return {
          url: '/admin',
          text: 'Go to Admin Dashboard'
        };
      case 'artist':
        return {
          url: '/artist-dashboard',
          text: 'Go to Artist Dashboard'
        };
      case 'podcaster':
        return {
          url: '/podcaster-dashboard',
          text: 'Go to Podcaster Dashboard'
        };
      default:
        return null;
    }
  };

  const dashboardLink = getDashboardLink();

  return (
    <div className="pt-20 min-h-screen bg-gradient-to-b from-purple-900 to-black text-white">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">My Profile</h1>
        
        {/* Status Messages */}
        {saveSuccess && (
          <div className="bg-green-500/20 border border-green-500 text-green-100 px-4 py-3 rounded mb-6">
            {saveSuccess}
          </div>
        )}
        
        {uploadSuccess && (
          <div className="bg-green-500/20 border border-green-500 text-green-100 px-4 py-3 rounded mb-6">
            {uploadSuccess}
          </div>
        )}
        
        {uploadError && (
          <div className="bg-red-500/20 border border-red-500 text-red-100 px-4 py-3 rounded mb-6">
            {uploadError}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Profile Image and Account Info Section */}
          <div className="md:col-span-1">
            <div className="bg-gray-800 rounded-lg p-6 mb-6">
              <div className="flex flex-col items-center mb-6">
                <img 
                  src={user?.profile_image_url || "https://via.placeholder.com/150?text=Profile"} 
                  alt={user?.username} 
                  className="w-32 h-32 rounded-full object-cover mb-4"
                />
                <h2 className="text-xl font-bold">{user?.full_name || user?.username}</h2>
                <span className="bg-purple-600/20 text-purple-300 px-3 py-1 rounded-full text-sm mt-2">
                  {user?.role.charAt(0).toUpperCase() + user?.role.slice(1)}
                </span>
                <p className="text-gray-400 text-sm mt-2">@{user?.username}</p>
              </div>
              
              <div className="mb-6">
                <h3 className="text-sm font-medium mb-2">Upload Profile Image</h3>
                <FileUploader 
                  endpoint="/api/upload/profile-image"
                  acceptedFileTypes="image/*"
                  maxFileSizeMB={5}
                  onUploadSuccess={handleUploadSuccess}
                  onUploadError={handleUploadError}
                  buttonText="Upload Image"
                />
              </div>
              
              {dashboardLink && (
                <div className="mt-6">
                  <a 
                    href={dashboardLink.url}
                    className="block w-full bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-md font-medium transition-colors text-center"
                  >
                    {dashboardLink.text}
                  </a>
                </div>
              )}
            </div>
            
            <div className="bg-gray-800 rounded-lg p-6">
              <h3 className="text-lg font-bold mb-4">Account Information</h3>
              <ul className="space-y-3">
                <li className="flex items-start">
                  <span className="text-gray-400 w-24">Username:</span>
                  <span className="font-medium">{user?.username}</span>
                </li>
                <li className="flex items-start">
                  <span className="text-gray-400 w-24">Email:</span>
                  <span className="font-medium">{user?.email}</span>
                </li>
                <li className="flex items-start">
                  <span className="text-gray-400 w-24">Role:</span>
                  <span className="font-medium capitalize">{user?.role}</span>
                </li>
                <li className="flex items-start">
                  <span className="text-gray-400 w-24">Joined:</span>
                  <span className="font-medium">
                    {new Date(user?.created_at).toLocaleDateString()}
                  </span>
                </li>
              </ul>
            </div>
          </div>
          
          {/* Profile Details Section */}
          <div className="md:col-span-2">
            <div className="bg-gray-800 rounded-lg p-6">
              <h3 className="text-lg font-bold mb-6">Profile Information</h3>
              
              <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium mb-1">Full Name</label>
                  <input 
                    type="text"
                    name="fullName"
                    value={formData.fullName}
                    onChange={handleChange}
                    className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    placeholder="Your full name"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium mb-1">Email</label>
                  <input 
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    placeholder="your@email.com"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium mb-1">Biography</label>
                  <textarea 
                    name="bio"
                    value={formData.bio}
                    onChange={handleChange}
                    className="w-full bg-gray-700 rounded-md py-2 px-4 focus:outline-none focus:ring-2 focus:ring-purple-500 min-h-[150px]"
                    placeholder="Tell us about yourself"
                  ></textarea>
                </div>
                
                <div className="pt-2">
                  <button 
                    type="submit"
                    className="bg-purple-600 hover:bg-purple-700 text-white py-2 px-6 rounded-md font-medium transition-colors"
                  >
                    Save Changes
                  </button>
                </div>
              </form>
            </div>
            
            <div className="bg-gray-800 rounded-lg p-6 mt-6">
              <h3 className="text-lg font-bold mb-4">Privacy & Security</h3>
              
              <div>
                <button 
                  className="bg-gray-700 hover:bg-gray-600 text-white py-2 px-6 rounded-md font-medium transition-colors"
                >
                  Change Password
                </button>
              </div>
              
              <div className="mt-6 space-y-4">
                <h4 className="font-medium">Email Preferences</h4>
                <div className="flex items-center">
                  <input 
                    type="checkbox" 
                    id="receiveNewsletters" 
                    className="h-4 w-4 rounded border-gray-600 text-purple-600 focus:ring-purple-500" 
                    defaultChecked
                  />
                  <label htmlFor="receiveNewsletters" className="ml-2 text-sm text-gray-300">
                    Receive newsletters and updates
                  </label>
                </div>
                <div className="flex items-center">
                  <input 
                    type="checkbox" 
                    id="receiveNotifications" 
                    className="h-4 w-4 rounded border-gray-600 text-purple-600 focus:ring-purple-500" 
                    defaultChecked
                  />
                  <label htmlFor="receiveNotifications" className="ml-2 text-sm text-gray-300">
                    Receive notification emails
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
