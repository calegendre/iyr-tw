import React, { useState, useRef } from 'react';
import axios from 'axios';
import { useAuth } from '../../contexts/AuthContext';

const FileUploader = ({ 
  endpoint, 
  acceptedFileTypes = "*", 
  maxFileSizeMB = 50,
  onUploadSuccess,
  onUploadError,
  buttonText = "Upload File",
  additionalFields = {},
  className = ""
}) => {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState('');
  const fileInputRef = useRef(null);
  const { token } = useAuth();

  // Convert MB to bytes
  const maxSizeBytes = maxFileSizeMB * 1024 * 1024;

  const handleFileSelect = (e) => {
    const selectedFile = e.target.files[0];
    setError('');
    
    // Validate file
    if (!selectedFile) return;
    
    // Check file size
    if (selectedFile.size > maxSizeBytes) {
      setError(`File size exceeds the ${maxFileSizeMB}MB limit`);
      return;
    }
    
    // Check file type if specified
    if (acceptedFileTypes !== "*") {
      const fileType = selectedFile.type;
      const acceptedTypes = acceptedFileTypes.split(',').map(type => type.trim());
      
      if (!acceptedTypes.some(type => fileType.match(new RegExp(type.replace('*', '.*'))))) {
        setError(`File type not accepted. Please upload ${acceptedFileTypes}`);
        return;
      }
    }
    
    setFile(selectedFile);
  };

  const handleUpload = async () => {
    if (!file || uploading) return;
    
    setUploading(true);
    setUploadProgress(0);
    setError('');
    
    const formData = new FormData();
    formData.append('file', file);
    
    // Add any additional fields
    Object.entries(additionalFields).forEach(([key, value]) => {
      formData.append(key, value);
    });
    
    try {
      const response = await axios.post(
        `${process.env.REACT_APP_BACKEND_URL}${endpoint}`,
        formData,
        {
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': `Bearer ${token}`
          },
          onUploadProgress: (progressEvent) => {
            const percentCompleted = Math.round(
              (progressEvent.loaded * 100) / progressEvent.total
            );
            setUploadProgress(percentCompleted);
          }
        }
      );
      
      if (onUploadSuccess) {
        onUploadSuccess(response.data);
      }
      
      // Reset after successful upload
      setFile(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    } catch (err) {
      console.error('Upload error:', err);
      setError(err.response?.data?.detail || 'Upload failed. Please try again.');
      
      if (onUploadError) {
        onUploadError(err);
      }
    } finally {
      setUploading(false);
    }
  };

  const handleReset = () => {
    setFile(null);
    setError('');
    setUploadProgress(0);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className={`bg-gray-800 rounded-lg p-4 ${className}`}>
      {error && (
        <div className="bg-red-500/20 border border-red-500 text-red-100 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}
      
      <div className="mb-4">
        <label className="block text-sm font-medium mb-2">
          Select file to upload
        </label>
        <input
          ref={fileInputRef}
          type="file"
          onChange={handleFileSelect}
          accept={acceptedFileTypes}
          className="w-full text-sm text-gray-400 bg-gray-700 rounded-md p-2.5 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-purple-600 file:text-white hover:file:bg-purple-700"
          disabled={uploading}
        />
      </div>
      
      {file && (
        <div className="mb-4">
          <p className="text-sm text-gray-300 mb-1">Selected file: <span className="font-semibold">{file.name}</span></p>
          <p className="text-xs text-gray-400">Size: {(file.size / 1024 / 1024).toFixed(2)} MB</p>
        </div>
      )}
      
      {uploading && (
        <div className="mb-4">
          <div className="flex items-center justify-between mb-1">
            <span className="text-sm text-gray-300">Uploading...</span>
            <span className="text-sm text-gray-300">{uploadProgress}%</span>
          </div>
          <div className="w-full bg-gray-700 rounded-full h-2.5">
            <div 
              className="bg-purple-600 h-2.5 rounded-full" 
              style={{ width: `${uploadProgress}%` }}
            ></div>
          </div>
        </div>
      )}
      
      <div className="flex space-x-3">
        <button
          onClick={handleUpload}
          disabled={!file || uploading}
          className={`px-4 py-2 rounded-md ${
            !file || uploading
              ? 'bg-gray-600 cursor-not-allowed'
              : 'bg-purple-600 hover:bg-purple-700'
          } text-white font-medium transition`}
        >
          {buttonText}
        </button>
        
        {file && (
          <button
            onClick={handleReset}
            disabled={uploading}
            className="px-4 py-2 rounded-md bg-gray-700 hover:bg-gray-600 text-white font-medium transition"
          >
            Reset
          </button>
        )}
      </div>
    </div>
  );
};

export default FileUploader;
