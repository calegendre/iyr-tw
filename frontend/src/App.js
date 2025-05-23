import React from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import "./App.css";

// Contexts
import { AuthProvider } from "./contexts/AuthContext";
import { MediaPlayerProvider } from "./contexts/MediaPlayerContext";

// Layout Components
import Header from "./components/layout/Header";
import Footer from "./components/layout/Footer";
import MediaPlayer from "./components/player/MediaPlayer";

// Pages
import Home from "./pages/Home";
import Artists from "./pages/Artists";
import Podcasts from "./pages/Podcasts";
import Blog from "./pages/Blog";
import Login from "./pages/Login";
import Register from "./pages/Register";
import ArtistDashboard from "./pages/artist/ArtistDashboard";
import PodcasterDashboard from "./pages/podcaster/PodcasterDashboard";
import AdminDashboard from "./pages/admin/AdminDashboard";
import ProfilePage from "./pages/profile/ProfilePage";

// Auth Components
import ProtectedRoute from "./components/auth/ProtectedRoute";

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <MediaPlayerProvider>
          <div className="App min-h-screen bg-gray-900 text-white flex flex-col">
            <Header />
            
            <main className="flex-grow pt-16">
              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/artists" element={<Artists />} />
                <Route path="/podcasts" element={<Podcasts />} />
                <Route path="/blog" element={<Blog />} />
                <Route path="/login" element={<Login />} />
                <Route path="/register" element={<Register />} />
                <Route path="/profile" element={
                  <ProtectedRoute>
                    <ProfilePage />
                  </ProtectedRoute>
                } />
                <Route path="/artist-dashboard" element={
                  <ProtectedRoute requiredRoles={['artist', 'admin', 'staff']}>
                    <ArtistDashboard />
                  </ProtectedRoute>
                } />
                <Route path="/podcaster-dashboard" element={
                  <ProtectedRoute requiredRoles={['podcaster', 'admin', 'staff']}>
                    <PodcasterDashboard />
                  </ProtectedRoute>
                } />
                <Route path="/admin" element={
                  <ProtectedRoute requiredRoles={['admin', 'staff']}>
                    <AdminDashboard />
                  </ProtectedRoute>
                } />
              </Routes>
            </main>
            
            <Footer />
            <MediaPlayer />
          </div>
        </MediaPlayerProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
